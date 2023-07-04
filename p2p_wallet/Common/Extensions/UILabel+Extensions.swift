import Foundation
import UIKit

extension UILabel {
    func setAttributeString(_ text: NSAttributedString) -> Self {
        attributedText = text
        return self
    }
}
