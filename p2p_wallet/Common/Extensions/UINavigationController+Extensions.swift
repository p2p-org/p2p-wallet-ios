import Foundation
import UIKit

extension UINavigationController {
    override open var childForStatusBarStyle: UIViewController? {
        topViewController
    }
}
