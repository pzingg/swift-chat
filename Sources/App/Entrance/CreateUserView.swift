import GtkBackend
import SwiftCrossUI
// PFZ
// import SwiftUI
// import ComposableArchitecture
import Foundation

// MARK: - Create room view

class CreateUserViewState: Observable {
  @Observed var name: String = ""
}

struct CreateUserView: View {

  let state = CreateUserViewState()
  let create: (String) -> ()

  var body: some View {
    VStack {
      TextField("Enter user name", state.$name)
      Button("Create", action: {
          create(state.name)
      })
      // .disabled(state.name.count < 3)
    }
    .padding(6)
    // .interactiveDismissDisabled()
  }
}
