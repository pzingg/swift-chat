import GtkBackend
import SwiftCrossUI
// PFZ
// import SwiftUI
// import ComposableArchitecture
import Foundation

// MARK: - Feature view

public struct EntranceView: View {
  // @Bindable
  public var state: Entrance.State

  public init(state: Entrance.State) {
    self.state = state
  }

  public var body: some View {
    ScrollView {
      ForEach(state.rooms) { room in
        RoomItemView(
          name: room.name,
          description: room.description
        ) {
          state.send(.selectRoom(room))
        }
      }
      .padding(6)
    }

    /*
    .searchable(text: state.$query)
    if state.isLoading {
      ProgressView()
    }
    .onAppear { state.send(.onAppear) }
    .sheet(
      item: state.$sheet
    ) {
      route in RouteView(...)
    }
    */

    if let route = state.sheet {
      RouteView(
        route: route,
        send: { action in
          switch action {
          case .createUser(let name):
            state.send(.createUser(name))
          case let .createRoom(name, description):
            state.send(.createRoom(name, description))
          }
        }
      )
    }

    Button("+", action: {
      // animation: .default
      state.send(.openCreateRoom)
    })
    // .id("addRoomButton")
  }
}

struct RouteView: View {

  // @Environment(\.dismiss)
  func dismiss() -> Void {

  }

  enum Action {
    case createUser(name: String)
    case createRoom(name: String, description: String?)
  }

  let route: Entrance.SheetRoute
  let send: (Action) -> ()

  var body: some View {
    // NavigationView?
    switch route {
    case .createUser:
      CreateUserView { userName in
        send(.createUser(name: userName))
      }
      // .navigationTitle("Create user")
    case .createRoom:
      CreateRoomView { userName, description in
        send(.createRoom(name: userName, description: description))
      }
      // .navigationTitle("Create room")
      Button("x", action: {
        self.dismiss()
      })
      // .id("navigationBarBackButton")
    }
  }
}

struct RoomItemView: View {

  let name: String
  let description: String?
  let open: () -> ()

  var body: some View {
    VStack() {
      Text(name)
      // .font(.headline)
      description.map {
        Text($0)
      } ?? Text("Unknown item")
      Spacer() // Divider()
    }
    .frame()
    // .onTapGesture {
    //  self.open()
    // }
  }
}

fileprivate extension Optional where Wrapped: Hashable {
  var isPresented: Bool {
    get { self != nil }
    set { if !newValue { self = nil } }
  }
}
