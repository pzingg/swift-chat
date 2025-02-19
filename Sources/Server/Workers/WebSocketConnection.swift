import HummingbirdWSCore
import HummingbirdWebSocket
import Hummingbird
import Foundation
import WebSocket
import Backend
import Persistence
import DistributedCluster
import PostgresNIO
import ServiceLifecycle

actor WebSocketConnection: WebSocketApi.ConnectionManager {
  
  let outboundCounnections: OutboundConnections
  let connectionStream: AsyncStream<WebSocketApi.Connection>
  let connectionContinuation: AsyncStream<WebSocketApi.Connection>.Continuation
  let logger: Logger
  
  public init(
    actorSystem: ClusterSystem,
    persistence: Persistence,
    logger: Logger = Logger(label: "WebSocketConnection")
  ) {
    self.logger = logger
    (self.connectionStream, self.connectionContinuation) = AsyncStream<WebSocketApi.Connection>.makeStream()
    self.outboundCounnections = OutboundConnections(
      actorSystem: actorSystem,
      persistence: persistence
    )
  }
  
  func run() async {
    await withGracefulShutdownHandler {
      await withDiscardingTaskGroup { group in
        for await connection in self.connectionStream {
          group.addTask {
            self.logger.info(
              "add connection",
              metadata: [
                "userId": .string(connection.info.userId.uuidString),
                "roomId": .string(connection.info.roomId.uuidString)
              ]
            )
            
            do {
              try await self.outboundCounnections.add(
                connection: connection
              )
              for try await input in connection.inbound.messages(maxSize: 1_000_000) {
                try await self.outboundCounnections.handle(input, from: connection)
              }
            } catch {
              self.logger.log(level: .error, .init(stringLiteral: error.localizedDescription))
            }
            
            self.logger.info(
              "remove connection",
              metadata: [
                "userId": .string(connection.info.userId.uuidString),
                "roomId": .string(connection.info.roomId.uuidString)
              ]
            )
            try? await self.outboundCounnections.remove(
              connection: connection
            )
            connection.outbound.finish()
          }
        }
        group.cancelAll()
      }
    } onGracefulShutdown: {
      self.connectionContinuation.finish()
    }
  }
  
  func add(
    info: WebSocketApi.Connection.Info,
    inbound: WebSocketInboundStream,
    outbound: WebSocketOutboundWriter
  ) -> WebSocketApi.ConnectionManager.OutputStream {
    let outputStream = WebSocketApi.ConnectionManager.OutputStream()
    let connection = WebSocketApi.Connection(info: info, inbound: inbound, outbound: outputStream)
    self.connectionContinuation.yield(connection)
    return outputStream
  }
}

actor OutboundConnections {
  
  let actorSystem: ClusterSystem
  let persistence: Persistence
  var outboundWriters: [WebSocketApi.Connection.Info: (User, Room)] = [:]
  
  func add(
    connection: WebSocketApi.Connection
  ) async throws {
    guard self.outboundWriters[connection.info] == nil else { return }
    let room = try await self.findRoom(with: connection.info)
    let userModel = try await persistence.getUser(id: connection.info.userId)
    let user: User = User(
      actorSystem: self.actorSystem,
      userInfo: .init(
        id: userModel.id,
        name: userModel.name
      ),
      reply: { messages in
        let response: [ChatResponse] = messages.map { (output: User.Output) -> ChatResponse in
          switch output {
          case let .message(messageInfo):
            return ChatResponse(
              user: .init(messageInfo.userInfo),
              message: .init(messageInfo.message)
            )
          }
        }
        var data = ByteBuffer()
        _ = try? data.writeJSONEncodable(response)
        await connection.outbound.send(.binary(data))
      }
    )
    try await user.send(message: .join, to: room)
    self.outboundWriters[connection.info] = (user, room)
  }
  
  func remove(
    connection: WebSocketApi.Connection
  ) async throws {
    guard let (user, room) = self.outboundWriters[connection.info] else { return }
    try await user.send(message: .leave, to: room)
    self.outboundWriters.removeValue(forKey: connection.info)
  }
  
  func handle(
    _ message: WebSocketMessage,
    from connection: WebSocketApi.Connection
  ) async throws {
    guard let (user, room) = self.outboundWriters[connection.info] else { return }
    switch message {
    case .text(let string):
      let createdAt = Date()
      try await user.send(
        message: .message(string, at: createdAt),
        to: room
      )
      var data = ByteBuffer()
      _ = try? await data.writeJSONEncodable(
        MessageInfo(
          roomInfo: room.info,
          userInfo: user.info,
          message: .message(string, at: createdAt)
        )
      )
      await connection.outbound.send(.binary(data))
    case .binary(var data):
      guard let messages = try? data.readJSONDecodable(
        [ChatResponse.Message].self,
        length: data.readableBytes
      ) else { break }
      var response: [ChatResponse] = []
      for message in messages {
        try await user.send(
          message: .init(message),
          to: room
        )
        try? await response.append(
          ChatResponse(
            user: .init(user.info),
            room: .init(room.info),
            message: message
          )
        )
      }
      var data = ByteBuffer()
      _ = try data.writeJSONEncodable(response)
      await connection.outbound.send(.binary(data))
    }
  }
  
  private func findRoom(
    with info: WebSocketApi.Connection.Info
  ) async throws -> Room {
    let roomModel = try await self.persistence.getRoom(id: info.roomId)
    return try await self.actorSystem.virtualActors.actor(id: info.roomId.uuidString) { actorSystem in
      await Room(
        actorSystem: actorSystem,
        roomInfo: .init(
          id: info.roomId,
          name: roomModel.name,
          description: roomModel.description
        )
      )
    }
  }
  
  init(
    actorSystem: ClusterSystem,
    persistence: Persistence
  ) {
    self.actorSystem = actorSystem
    self.persistence = persistence
  }
}

fileprivate extension ChatResponse.Message {
  init(_ message: User.Message) {
    self = switch message {
    case .join: .join
    case .message(let string, let date): .message(string, at: date)
    case .leave: .leave
    case .disconnect: .disconnect
    }
  }
}

fileprivate extension User.Message {
  init(_ message: ChatResponse.Message) {
    self = switch message {
    case .join: .join
    case .message(let string, let date): .message(string, at: date)
    case .leave: .leave
    case .disconnect: .disconnect
    }
  }
}

fileprivate extension UserResponse {
  init(_ userInfo: User.Info) {
    self.init(
      id: userInfo.id.rawValue,
      name: userInfo.name
    )
  }
}

fileprivate extension UserResponse {
  init(_ userModel: UserModel) {
    self.init(
      id: userModel.id,
      name: userModel.name
    )
  }
}


fileprivate extension RoomResponse {
  init(_ roomInfo: Room.Info) {
    self.init(
      id: roomInfo.id.rawValue,
      name: roomInfo.name,
      description: roomInfo.description
    )
  }
}
