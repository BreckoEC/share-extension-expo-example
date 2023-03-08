import LinkPresentation
import SwiftUI
import AVFoundation

/**
 This class is used to share data with the main app
 */
struct Keychain {
  var api: String

  init() throws {
    guard let group = (Bundle.main.object(forInfoDictionaryKey: "ShareExtensionKeychainAccessGroup") as? String),
          let api = Keychain.getValue(forKey: "api", inGroup: group)
    else {
      throw CustomError.generic("Failed to find 'api' or 'userId' from the keychain")
    }

    self.api = api.trimmingCharacters(in: ["/"])
  }

  private static func getValue(forKey key: String, inGroup group: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrAccessGroup as String: group,
      kSecReturnData as String: true,
      kSecReturnAttributes as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    guard status == errSecSuccess,
          let existingItem = item as? [String : AnyObject],
          let itemData = existingItem[kSecValueData as String] as? Data,
          let result = String(data: itemData, encoding: .utf8)
    else {
      return nil
    }

    return result
  }
}

/**
 Helper to handle api calls
 */
struct ApiClient {
  private var api: URL

  init() throws {
    let keychain = try Keychain()
    guard let api = URL(string: keychain.api) else {
      throw CustomError.generic("Failed to create an url from given api host")
    }
    self.api = api
  }

  func getUsers() async throws -> [User] {
    let request = try createRequest(for: "users")
    let (data, response) = try await URLSession.shared.data(for: request)
    try validateResponse(response, with: data)
    return try JSONDecoder().decode([User].self, from: data)
  }

  func send(attachment: Attachment, to user: User) async throws {
    try await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1 second

    // Here you have to handle the attachment to create a POST request to your API
  }

  private func createRequest(for endpoint: String, with payload: Data? = nil) throws -> URLRequest {
    guard let url = URL(string: endpoint, relativeTo: api) else {
      throw CustomError.generic("Failed to create URL endpoint from '\(endpoint)'")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let payload = payload {
      request.httpMethod = "POST"
      request.httpBody = payload
    }

    return request
  }

  private func validateResponse(_ response: URLResponse, with data: Data) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw CustomError.generic("Failed to cast response to http response")
    }

    if (200...299).contains(httpResponse.statusCode) {
      return
    }

    throw CustomError.generic("""
                              Something failed with the api call.
                              HTTP Status Code: '\(httpResponse.statusCode)'
                              Response:
                              \(String(data: data, encoding: .utf8)!)
                              """)
  }
}

/**
 SwiftUI View to handle user display
 */
struct UserView: View {
  @State var user: User

  var body: some View {
    HStack {
      AsyncImage(url: URL(string: user.picture)) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)

      } placeholder: {
        ProgressView()
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())

      VStack {
        Text(user.name)
          .lineLimit(1)
          .padding(.top, 8)

        Text("@\(user.username)")
          .lineLimit(1)
          .font(.footnote)
          .padding(.leading, -8.0)
          .foregroundColor(.gray)
      }

      Spacer()

      HStack {
        Text(user.phone)
          .lineLimit(1)
          .foregroundColor(.gray)
      }
    }
  }
}

/**
 SwiftUI View to handle error display
 */
struct CustomErrorView: View {
  @State var error: String

  var body: some View {
    HStack {
      ZStack {
        VStack {
          Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
            .symbolVariant(.fill)
            .font(.largeTitle)
            .foregroundColor(.red)
          Text(error)
            .padding()
        }

        VStack {
          HStack {
            Button(action: {
              NotificationCenter.default.dismiss("Dismiss")
            }) {
              Image(systemName: "xmark")
            }
            .font(.system(size: 22))
            .padding(.top, -4)
            Spacer()
          }
          Spacer()
        }
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    .edgesIgnoringSafeArea(.all)
    .padding()
    .background(Color(red: 0, green: 0, blue: 0, opacity: 0.8))
    .foregroundColor(.white)
  }
}

/**
 Required to subclass LPLinkView to fix intrinsicContentSize (otherwise, height is not controlable)
 */
class CustomLinkView: LPLinkView {
  override var intrinsicContentSize: CGSize { CGSize(width: super.intrinsicContentSize.width, height: 0) }
}

/**
 SwiftUI View to handle URL preview
 */
struct URLPreview : UIViewRepresentable {

  var url: URL

  func makeUIView(context: Context) -> CustomLinkView {
    CustomLinkView(url: url)
  }

  func updateUIView(_ view: CustomLinkView, context: Context) {
    let provider = LPMetadataProvider()
    provider.startFetchingMetadata(for: url) { (metadata, _) in
      if let md = metadata {
        DispatchQueue.main.async {
          view.metadata = md
          view.sizeToFit()
        }
      }
    }
  }
}
