import Foundation
import UIKit

extension NSAttributedString {
    
    func withForegroundColor(_ color: UIColor) -> NSAttributedString {
        let string = NSMutableAttributedString(attributedString: self)
        string.addAttributes([.foregroundColor: color], range: .init(location: 0, length: self.string.count))
        return string
    }
    
}

extension String {
    
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (self as NSString).size(withAttributes: fontAttributes)
        return size.width
    }
}
