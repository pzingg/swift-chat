import DistributedCluster
import VirtualActor
import Backend
import EventSource

enum RoomNode: Node {
  static func run(
    host: String,
    port: Int
  ) async throws {
    let roomNode = await ClusterSystem("room") {
      $0.bindHost = host
      $0.bindPort = port
      $0.installPlugins()
    }
    roomNode.cluster.join(host: "127.0.0.1", port: 2550) // <- here should be `seed` host and port
    try await Self.ensureCluster(roomNode, within: .seconds(10))
    await roomNode.virtualActors.addNode(VirtualNode(actorSystem: roomNode))
    try await roomNode.terminated
  }
}
