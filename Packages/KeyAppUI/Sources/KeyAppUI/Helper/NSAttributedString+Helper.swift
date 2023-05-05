import Foundation
import UIKit

public extension NSAttributedString {
    
    func withForegroundColor(_ color: UIColor) -> NSAttributedString {
        let string = NSMutableAttributedString(attributedString: self)
        string.addAttributes([.foregroundColor: color], range: .init(location: 0, length: self.string.count))
        return string
    }
    
}
