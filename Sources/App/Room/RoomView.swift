import GtkBackend
import SwiftCrossUI
// PFZ
// import SwiftUI
// import ComposableArchitecture
import Foundation

// MARK: - Feature view

public struct RoomView: View {

  // @Bindable
  var store: Room.State

  public init(store: Room.State) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        // ForEach(Array(store.receivedMessages.enumerated()), id: \.0) { (index, response) in
        ForEach(
          Array(
            store.receivedMessages.enumerated()
          )
          //, id: \.0
        ) { (_, response) in
          switch response.message {
          case .join:
            Text("\(response.user.name) joined the chat. 🎉🥳")
          case .disconnect:
            Text("\(response.user.name) disconnected. 💤😴")
          case .leave:
            Text("\(response.user.name) left the chat. 👋🥲")
          case .message(let message, _) where response.user == store.user:
            UserMessage(message: message)
          case .message(let message, _):
            OtherUsersMessage(name: response.user.name, message: message)
          }
        }
        ForEach(
          Array(
            zip(
              store.messagesToSendTexts.indices,
              store.messagesToSendTexts
            )
          )
          //, id: \.0
        ) { (_, text) in
          MessageToSend(message: text)
        }
        .padding(6)
        /*
        .onChange(of: store.receivedMessages) { oldValue, messages in
          guard let last = messages.last else { return }
          // reader.scrollTo(last.id, anchor: .top)
        }
        .onChange(of: store.messagesToSend) { oldValue, messages in
          guard !messages.isEmpty else { return }
          // reader.scrollTo(messages.count - 1, anchor: .top)
        }
        */
      }
      Spacer() // Divider()
      MessageField(
        message: store.$message,
        isSending: store.isSending,
        send: { store.send(.sendButtonTapped) }
      )
    }
    // .onAppear { store.send(.onAppear) }
    // .navigationTitle(store.room.name)
  }
}

struct UserMessage: View {

  let message: String

  // TODO: Capsule shape around Text, .background
  var body: some View {
    HStack {
      Spacer()
      Text(message)
        .foregroundColor(Color.blue)
        .padding([.leading, .trailing], 6)
        .padding([.top, .bottom], 4)
    }
  }
}

struct OtherUsersMessage: View {

  let name: String
  let message: String

  // TODO: Capsule shape around Text, background
  var body: some View {
    HStack {
      VStack(spacing: 2) {
        Text(name + ":")
          // .font(.footnote)
          // .foregroundStyle(Color.secondary)
        Text(message)
          .foregroundColor(Color.green)
          .padding([.leading, .trailing], 6)
          .padding([.top, .bottom], 4)
      }
      Spacer()
    }
  }
}

struct MessageToSend: View {

  let message: String

  // TODO: Capsule shape around Text, background
  var body: some View {
    HStack {
      Spacer()
      Text(message)
        .foregroundColor(Color.gray)
        .padding([.leading, .trailing], 6)
        .padding([.top, .bottom], 4)
      // ProgressView()
    }
  }
}

struct MessageField: View {

  var message: Binding<String>
  let isSending: Bool
  let send: () -> ()

  var body: some View {
    HStack {
      TextField("Enter message", message)
      Spacer()
      Button("Send", action: {
        send()
      })
      // .disabled(isSending)
    }
    .padding(6)
  }
}
