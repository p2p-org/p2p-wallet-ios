import Foundation
import UIKit

extension UIApplication {
    var kWindow: UIWindow? {
        // keyWindow is deprecated
        UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    class func topmostViewController(controller: UIViewController? = rootViewController()) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topmostViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topmostViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topmostViewController(controller: presented)
        }
        return controller
    }

    class func rootViewController() -> UIViewController? {
        UIApplication.shared.keyWindow?.rootViewController
    }

    class func dismissCustomPresentedViewController(completion: (() -> Void)? = nil) {
        guard let topmostVC = topmostViewController() else {
            completion?()
            return
        }
        if topmostVC.presentationController is DimmPresentationController ||
            topmostVC.navigationController?.presentationController is DimmPresentationController ||
            topmostVC.presentationController is ModalPresentationController
        {
            topmostVC.dismiss(animated: true, completion: completion)
        } else {
            completion?()
        }
    }
}
