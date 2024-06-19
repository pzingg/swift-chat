// PFZ
import GtkBackend
import SwiftCrossUI
import Dependencies
import ComposableArchitecture
import Foundation
import API
import WebSocket

public struct Room {

  @Dependency(\.continuousClock) var clock
  @Dependency(\.webSocket) var webSocket

  public class State : Observable {

    // TODO
    // var alert: AlertState<Action.Alert>?
    var alert: String?
    @Observed var message: String = ""
    var isSending: Bool = false

    let room: RoomPresentation
    let user: UserPresentation

    var connectivityState = ConnectivityState.disconnected
    var messagesToSend: [Message] = []
    var messagesToSendTexts: [String] {
      self.messagesToSend
        .compactMap { message in
          switch message {
          case .message(let text, _): text
          default: .none
          }
        }
    }
    var receivedMessages: [MessagePresentation] = []

    public enum ConnectivityState: String {
      case connected
      case connecting
      case disconnected
    }

    // PFZ
    // alert: AlertState<Action.Alert>? = nil,
    public init(
      user: UserPresentation,
      room: RoomPresentation,
      alert: String? = nil,
      connectivityState: ConnectivityState = ConnectivityState.disconnected,
      messagesToSend: [Message] = [],
      receivedMessages: [MessagePresentation] = []
    ) {
      self.user = user
      self.room = room
      self.alert = alert
      self.connectivityState = connectivityState
      self.messagesToSend = messagesToSend
      self.receivedMessages = receivedMessages
    }

    public func send(_ action: Room.Action) -> Void {

    }
  }

  public init() {}

  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    // PFZ
    // case alert(PresentationAction<Alert>)
    case alert(Alert)
    case connect
    case messageToSendAdded(Message)
    case receivedSocketMessage(Result<WebSocketClient.Message, any Error>)
    case sendButtonTapped
    case send([Message])
    case didSend(Result<Bool, any Error>)
    case webSocket(WebSocketClient.Action)

    public enum Alert: Equatable {}
  }

  /*
  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          await send(.connect)
        }
      case .alert:
        return .none

      case .connect:
        switch state.connectivityState {
        case .connected, .connecting:
          state.connectivityState = .disconnected
          return .cancel(id: WebSocketClient.ID())

        case .disconnected:
          state.connectivityState = .connecting
          let userId = state.user.id
          let roomId = state.room.id
          let messages = state.messagesToSend
          return .run { send in
            let actions = await self.webSocket
              .open(WebSocketClient.ID(), URL(string: "ws://localhost:8080/chat?room_id=\(roomId)&user_id=\(userId)")!, [])
            if !messages.isEmpty {
              await send(.send(messages))
            }
            await withThrowingTaskGroup(of: Void.self) { group in
              for await action in actions {
                // NB: Can't call `await send` here outside of `group.addTask` due to task local
                //     dependency mutation in `Effect.{task,run}`. Can maybe remove that explicit task
                //     local mutation (and this `addTask`?) in a world with
                //     `Effect(operation: .run { ... })`?
                group.addTask { await send(.webSocket(action)) }
                switch action {
                case .didOpen:
                  group.addTask {
                    while !Task.isCancelled {
                      try await self.clock.sleep(for: .seconds(10))
                      try await self.webSocket.sendPing(WebSocketClient.ID())
                    }
                  }
                  group.addTask {
                    for await result in try await self.webSocket.receive(WebSocketClient.ID()) {
                      await send(.receivedSocketMessage(result))
                    }
                  }
                case .didClose:
                  print("didClose")
                  return
                }
              }
            }
          }
          .cancellable(id: WebSocketClient.ID())
        }

      case let .messageToSendAdded(message):
        state.messagesToSend.append(message)
        return .none

      case let .receivedSocketMessage(.success(message)):
        if case let .data(data) = message,
          let messages = try? JSONDecoder()
            .decode([WebSocket.ChatResponse].self, from: data)
            .map(MessagePresentation.init)
        {
          for message in messages.filter({ $0.user.id == state.user.id }) {
            state.messagesToSend.removeAll(where: { $0 == message.message })
          }
          state.receivedMessages.append(contentsOf: messages)
        }
        return .none
      case .receivedSocketMessage(.failure):
        state.connectivityState = .disconnected
        return .run { send in
          try await self.webSocket.close(WebSocketClient.ID(), .normalClosure, .none)
        }
      case .send(let messages):
        state.isSending = true
        return .run { send in
          await send(
            .didSend(
              Result {
                let messages: [WebSocket.ChatResponse.Message] = messages.map {
                  switch $0 {
                  case .disconnect: .disconnect
                  case .join: .join
                  case .leave: .leave
                  case let .message(text, at: date): .message(text, at: date)
                  }
                }
                let data = try JSONEncoder().encode(messages)
                try await self.webSocket.send(WebSocketClient.ID(), .data(data))
                return true
              }
            )
          )
        }
      case .sendButtonTapped:
        guard !state.message.isEmpty else { return .none }
        let message = state.message
        state.message = ""
        state.messagesToSend.append(.message(message, at: Date()))
        let messagesToSend = state.messagesToSend
        return .run { send in
          await send(.send(messagesToSend))
        }.cancellable(id: WebSocketClient.ID())
      case let .didSend(.failure(error)):
        state.isSending = false
        state.alert = AlertState {
          TextState(
            """
            Could not send socket message.
            Reason: \(error.localizedDescription).
            Connect to the server first, and try again.
            """
          )
        }
        return .none

      case .didSend(.success):
        state.isSending = false
        return .none
      case .webSocket(.didClose):
        state.connectivityState = .disconnected
        return .run { send in
          Task.cancel(id: WebSocketClient.ID())
          try await Task.sleep(for: .seconds(3))
          await send(.connect)
        }
      case .webSocket(.didOpen):
        state.connectivityState = .connected
        state.receivedMessages.removeAll()
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.alert, action: /Action.alert)
  }
  */

}

extension MessagePresentation {
  init(_ message: WebSocket.ChatResponse) {
    self.user = .init(message.user)
    self.room = message.room.map(RoomPresentation.init)
    self.message = switch message.message {
    case .disconnect: .disconnect
    case .join: .join
    case .leave: .leave
    case let .message(text, at: date): .message(text, at: date)
    }
  }
}

extension UserPresentation {
  init(_ user: WebSocket.UserResponse) {
    self.id = user.id
    self.name = user.name
  }
}

extension RoomPresentation {
  init(_ room: WebSocket.RoomResponse) {
    self.id = room.id
    self.description = room.description
    self.name = room.name
  }
}
