import GtkBackend
import SwiftCrossUI
// PFZ
// import SwiftUI
// import ComposableArchitecture
import Foundation

// MARK: - Feature view

public struct EntranceView: View {
  // @Bindable
  var store: Entrance.State

  public init(store: Entrance.State) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      ForEach(store.rooms) { room in
        RoomItemView(
          name: room.name,
          description: room.description
        ) {
          store.send(.selectRoom(room))
        }
      }
      .padding(6)
    }

    /*
    .searchable(text: store.$query)
    if store.isLoading {
      ProgressView()
    }
    .onAppear { store.send(.onAppear) }
    .sheet(
      item: store.$sheet
    ) { route in
      RouteView(
        route: route,
        send: { action in
          switch action {
          case .createUser(let name):
            store.send(.createUser(name))
          case let .createRoom(name, description):
            store.send(.createRoom(name, description))
          }
        }
      )
    }
    */

    Button("+", action: {
      // animation: .default
      store.send(.openCreateRoom)
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

  let route: Entrance.State.Navigation.SheetRoute
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
