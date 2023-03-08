import UniformTypeIdentifiers
import UIKit

/**
 Struct of user as defined by https://jsonplaceholder.typicode.com/
 */
struct User: Identifiable, Codable {
  var id: Int
  var name: String
  var username: String
  var phone: String

  // The API used does not provide user thumbnail :(
  var picture = "https://www.gravatar.com/avatar/6ed6da5f61da2e30d23693bf7c612bd4"

  enum CodingKeys: String, CodingKey {
    case id = "id"
    case name = "name"
    case username = "username"
    case phone = "phone"
  }

  static let sample = samples.first!
  static let samples = (0..<5).map {
    User(id: $0, name: "User #\($0)", username: "user-\($0)", phone: "000000000\($0)")
  }
}

/**
 Enum used to share data in this extension
 */
enum Attachment {
  case text(String)
  case image(URL)
  case screenshot(UIImage)
  case url(URL)

  var contentType: String {
    switch self {
      case .text(_): return "application/json"
      case .image(let url): return url.guessMimeType()
      case .screenshot(_): return "image/png"
      case .url(_): return "application/json"
    }
  }
}

/**
 Data extension to support append with String
 */
extension Data {
  mutating func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}

/**
 URL extension to get the mimeType of a URL easily
 */
extension URL {
  func guessMimeType() -> String {
    if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
      return mimeType
    } else {
      return "application/octet-stream"
    }
  }
}

/**
 List of all internal notifications used to communicate from swiftUI views to the main controller
 */
extension Notification.Name {
  static let dismiss = Notification.Name("ShareExtensionDismiss")
}

/**
 URL extension to send the dismiss notification easily
 */
extension NotificationCenter {
  func dismiss(_ message: String) {
    let object = NotificationObject(message: message)
    post(name: .dismiss, object: object)
  }
}

/**
 Struct used in notifications sent from swiftUI views to the main controller
 */
struct NotificationObject {
  var message: String
}

/**
 List of all errors of this extension
 */
enum CustomError: Error {
  case generic(String)
}
