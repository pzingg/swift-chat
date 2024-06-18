import API
import OpenAPIURLSession
import Dependencies
// PFZ
// import ComposableArchitecture
import Foundation

// PFZ - adding @retroactive
// warning: extension declares a conformance of imported type 'Client' to
// imported protocols 'DependencyKey', 'TestDependencyKey'; this will not
// behave correctly if the owners of 'API' introduce this conformance in
// the future

extension Client: @retroactive DependencyKey {
  public static let liveValue: Client = {

    // @Shared(.appStorage("host"))
    var host: String?

    let baseUrl = host ?? "http://localhost:8080"

    return Client(
      serverURL: URL(string: baseUrl)!,
      transport: URLSessionTransport()
    )
  }()
}

extension DependencyValues {
  var client: Client {
    get { self[Client.self] }
    set { self[Client.self] = newValue }
  }
}
