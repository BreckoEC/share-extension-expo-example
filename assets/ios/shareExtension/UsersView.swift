import SwiftUI
import Intents
import UniformTypeIdentifiers

struct UsersView: View {
  @State var users: [User]
  @State var attachment: Attachment

  var body: some View {
    NavigationView {
      List {
        ForEach(users) { user in
          NavigationLink(destination: ShareView(user: user,
                                                attachment: attachment)) {
            UserView(user: user)
          }
        }
      }

      .navigationTitle("Users")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(action: {
            NotificationCenter.default.dismiss("User canceled")
          }) {
            Image(systemName: "xmark")
          }
        }
      }
    }
  }
}

struct UsersView_Previews: PreviewProvider {
  static var previews: some View {
    UsersView(users: User.samples,
              attachment: .text("Sample text"))
  }
}
