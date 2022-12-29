import Foundation
import SwiftUI

extension UIHostingController {
    /// Convenience init for overriding default avoiding-keyboard behavior in UIHostingController
    convenience public init(rootView: Content, ignoresKeyboard: Bool) {
        self.init(rootView: rootView)

        if ignoresKeyboard {
            // get the class
            guard let viewClass = object_getClass(view) else { return }

            // replace view's class by _IgnoresKeyboard alternative class
            let viewSubclassName = String(cString: class_getName(viewClass)).appending("_IgnoresKeyboard")
            
            // if _IgnoresKeyboard class is available
            if let viewSubclass = NSClassFromString(viewSubclassName) {
                object_setClass(view, viewSubclass)
            }
            
            // _IgnoresKeyboard is not available, observe the keyboard event and disable re-layout behavior
            else {
                guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else { return }
                guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else { return }

                if let method = class_getInstanceMethod(viewClass, NSSelectorFromString("keyboardWillShowWithNotification:")) {
                    let keyboardWillShow: @convention(block) (AnyObject, AnyObject) -> Void = { _, _ in }
                    class_addMethod(viewSubclass, NSSelectorFromString("keyboardWillShowWithNotification:"),
                                    imp_implementationWithBlock(keyboardWillShow), method_getTypeEncoding(method))
                }
                objc_registerClassPair(viewSubclass)
                object_setClass(view, viewSubclass)
            }
        }
    }
}
