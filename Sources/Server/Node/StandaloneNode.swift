import DistributedCluster
import Backend
import VirtualActor
import EventSource

enum StandaloneNode: Node {
  static func run(
    host: String,
    port: Int
  ) async throws {
    let mainNode = await ClusterSystem("main") {
      $0.bindHost = host
      $0.bindPort = port
      $0.installPlugins()
    }
    let roomNode = await ClusterSystem("roomNode") {
      $0.bindHost = host
      $0.bindPort = port + 1
      $0.installPlugins()
    }

    roomNode.cluster.join(node: mainNode.cluster.node)

    try await Self.ensureCluster(mainNode, roomNode, within: .seconds(10))

    // We need references for ARC not to clean them up
    let _ = try await FrontendNode(
      actorSystem: mainNode
    )
    try await mainNode.terminated
  }
}
