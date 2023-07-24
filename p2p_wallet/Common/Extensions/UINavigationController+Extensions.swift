import Foundation
import UIKit

extension UINavigationController {
    override open var childForStatusBarStyle: UIViewController? {
        topViewController
    }
}

extension UINavigationController {
    // True if `hidesBottomBarWhenPushed` can be set to true, otherwise false.
    // Workaround for iOS 14 bug.
    var canHideBottomForNextPush: Bool {
        // There is a bug in iOS 14 that hides the bottom bar
        // when popping multiple navigation controllers from the stack,
        // and one of them has hidesBottomBarWhenPushed set to true.
        // https://developer.apple.com/forums/thread/660750
        viewControllers.count == 1
    }
}
