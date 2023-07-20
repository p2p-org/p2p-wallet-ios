import Foundation
import UIKit

protocol ClipboardManagerType {
    func copyToClipboard(_ string: String)
    func copyToClipboard(_ image: UIImage)
    func stringFromClipboard() -> String?
}

class ClipboardManager: ClipboardManagerType {
    func copyToClipboard(_ string: String) {
        // swiftlint:disable clipboard_direct_api
        UIPasteboard.general.string = string
        // swiftlint:enable clipboard_direct_api
    }

    /// copy an image to a clipboard
    func copyToClipboard(_ image: UIImage) {
        UIPasteboard.general.image = image
    }

    func stringFromClipboard() -> String? {
        // swiftlint:disable clipboard_direct_api
        UIPasteboard.general.string
        // swiftlint:enable clipboard_direct_api
    }
}
