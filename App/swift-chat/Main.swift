import GtkBackend
import SwiftCrossUI
// PFZ
// import SwiftUI
// import ComposableArchitecture
import App

@main
// @HotReloadable
struct Main: SwiftCrossUI.App {
  let identifier = "dev.pzingg.SwiftChat"
  let state = Entrance.State()

  var body: some Scene {
    WindowGroup("Navigation") {
      NavigationStack(path: state.$path) {
        EntranceView(
          state: state
        )
      }
    }
  }
}
