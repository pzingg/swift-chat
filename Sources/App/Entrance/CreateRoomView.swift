import GtkBackend
import SwiftCrossUI
// PFZ
// import SwiftUI
// import ComposableArchitecture
import Foundation

// MARK: - Create room view


class CreateRoomViewState: Observable {
  @Observed var name: String = ""
  @Observed var description: String = ""
}

struct CreateRoomView: View {

  let state = CreateRoomViewState()
  let create: (String, String?) -> ()

  var body: some View {
    VStack {
      TextField("Enter room name", state.$name)
      TextField("Enter room description", state.$description)
      Button("Create", action: {
          create(state.name, state.description.isEmpty ? .none : state.description)
      })
      // .disabled(state.name.count < 3)
    }
    .padding(6)
  }
}
