import API
import OpenAPIURLSession
import Dependencies
// PFZ
// import ComposableArchitecture
import Foundation

extension Client: DependencyKey {
  public static let liveValue: Client = {
    @Shared(.appStorage("host")) var host: String?
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
