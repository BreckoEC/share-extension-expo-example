import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
  @IBOutlet var container: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Subscribe to swift UI events
    NotificationCenter.default.addObserver(self, selector: #selector(didSelectDismiss), name: .dismiss, object: nil)

    // Check that a single attachment is provided
    guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
          let item = extensionItem.attachments?.first
    else {
      presentSwiftUIView(CustomErrorView(error: "Failed to get attachment"))
      return
    }

    Task {
      do {
        // Create api client
        let apiClient = try ApiClient()

        // Get real attachment
        let attachmentType = try getAttachmentType(from: item)
        let attachment = try await getAttachment(from: item, withType: attachmentType)

        // Get users to present
        let users = try await apiClient.getUsers()

        // Present Boards View
        presentSwiftUIView(UsersView(users: users, attachment: attachment))
      } catch CustomError.generic(let internalError) {
        presentSwiftUIView(CustomErrorView(error: internalError))
      } catch {
        presentSwiftUIView(CustomErrorView(error: "\(error)"))
      }
    }
  }

  /**
   Regarding the conforming types of the provided item, returns the handled identifier
   */
  private func getAttachmentType(from item: NSItemProvider) throws -> String {
    if item.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
      return UTType.text.identifier
    }
    if item.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      return UTType.image.identifier
    }
    if item.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      // keep this as the last one otherwise it might prevent other url types to be detected as they should
      // most of local files are also identified as file-url (which is an url)
      return UTType.url.identifier
    }
    throw CustomError.generic("Cannot handle this type of attachments")
  }

  /**
   Load data of the provided item and return them in the right format for later use
   */
  private func getAttachment(from item: NSItemProvider, withType type: String) async throws -> Attachment {
    let data = try await item.loadItem(forTypeIdentifier: type)

    switch type {
      case UTType.text.identifier:
        guard let message = data as? String else {
          throw CustomError.generic("Failed to load item attached")
        }
        return .text(message)

      case UTType.image.identifier:
        if let url = data as? URL {
          return .image(url)
        }
        // if it is a "not saved yet" screenshot, the content is the image itself
        if let image = data as? UIImage {
          return .screenshot(image)
        }
        throw CustomError.generic("Failed to load item attached")

      case UTType.url.identifier:
        guard let url = data as? URL else {
          throw CustomError.generic("Failed to load item attached")
        }
        return .url(url)

      default:
        throw CustomError.generic("Failed to handle attachment type '\(type)'")
    }
  }

  /**
   Convenience method to present a swift UI view in the main storyboard
   */
  private func presentSwiftUIView<T>(_ view: T) where T : View {
    let swiftUIView = UIHostingController(rootView: view)
    self.addChild(swiftUIView)
    swiftUIView.view.frame = self.container.bounds
    self.container.addSubview(swiftUIView.view)
    swiftUIView.didMove(toParent: self)
  }

  /**
   This is called from notifications sent by Swift UI views
   */
  @objc private func didSelectDismiss(_ notification: Notification) {
    var message = "Failed to get notification object"
    if let object = notification.object as? NotificationObject {
      message = object.message
    }

    print(message)
    extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
  }
}
