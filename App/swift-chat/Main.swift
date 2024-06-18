import GtkBackend
import SwiftCrossUI
// PFZ
// import SwiftUI
// import ComposableArchitecture
import App

@main
struct Main: SwiftCrossUI.App {

  let store: Entrance = Entrance.State()

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        EntranceView(
          store: store
        )
      }
    }
  }
}
