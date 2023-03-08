import SwiftUI

/**
 Main view
 */
struct ShareView: View {
  @State var user: User
  @State var attachment: Attachment

  @State var sending = false
  @State var sendingError: String?

  private func send() async {
    sending = true

    // Send to the server
    do {
      let apiClient = try ApiClient()
      /*
      try await apiClient.addBlock(named: givenName,
                                   with: attachment,
                                   to: selectedThreads)
       */
    } catch CustomError.generic(let message) {
      sendingError = message
      return
    } catch {
      sendingError = "\(error)"
      return
    }

    NotificationCenter.default.dismiss("Sent successfully !")
  }

  var body: some View {
    ZStack {
      NavigationView {
        VStack {
          HStack {
            Text("User selected:")
              .font(.headline)
              .padding()
            Spacer()
          }

          UserView(user: user)
            .padding(.horizontal)

          HStack {
            Text("Content about to be shared:")
              .font(.headline)
              .padding()
            Spacer()
          }

          switch attachment {
            case .text(let message):
              HStack {
                Text(message)
                  .multilineTextAlignment(.leading)
                Spacer()
              }
              .padding(.horizontal)

            case .image(let url), .url(let url):
              VStack {
                URLPreview(url: url)
              }
              .padding(.horizontal)
              .frame(maxHeight: 300)

            case .screenshot(let image):
              VStack {
                Image(uiImage: image)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .clipShape(RoundedRectangle(cornerRadius: 25))
              }
              .padding(.horizontal)
              .frame(maxHeight: 300)
          }

          Spacer()
        }

        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(action: {
              NotificationCenter.default.dismiss("User canceled")
            }) {
              Image(systemName: "xmark")
            }
            .disabled(sending)
          }

          ToolbarItem(placement: .confirmationAction) {
            Button(action: {
              Task {
                await send()
              }
            }) {
              Image(systemName: "paperplane")
                .symbolVariant(.fill)
            }
            .disabled(sending)
          }
        }
      }
      .blur(radius: sending ? 3 : 0)

      if sending {
        if let error = sendingError {
          CustomErrorView(error: error)
        } else {
          HStack {
            ProgressView {
              Text("Sending...")
            }
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
          }
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
          .edgesIgnoringSafeArea(.all)
          .padding()
          .background(Color(red: 0, green: 0, blue: 0, opacity: 0.8))
          .foregroundColor(.white)
        }
      }
    }
  }
}

/**
 Preview available on XCode's Canvas
 */
struct ShareView_Previews: PreviewProvider {
  static var previews: some View {
    ShareView(user: User.sample,
              attachment: .text("Sample text"))
    .previewDisplayName("Text")

    ShareView(user: User.sample,
              attachment: .image(URL(string: "https://via.placeholder.com/1024")!))
    .previewDisplayName("Image")

    ShareView(user: User.sample,
              attachment: .screenshot(UIImage(systemName: "car")!))
    .previewDisplayName("Screenshot")

    ShareView(user: User.sample,
              attachment: .url(URL(string: "https://www.apple.com/in/ios/ios-16/")!))
    .previewDisplayName("URL")

    ShareView(user: User.sample,
              attachment: .text("Sample text"),
              sending: true)
    .previewDisplayName("Sending")

    ShareView(user: User.sample,
              attachment: .text("Sample text"),
              sending: true,
              sendingError: "Failed to send data")
    .previewDisplayName("Sending Error")
  }
}
