import Foundation
import UIKit

extension NSMutableAttributedString {
    @discardableResult
    func appending(_ attributedString: NSAttributedString) -> Self {
        append(attributedString)
        return self
    }
}
