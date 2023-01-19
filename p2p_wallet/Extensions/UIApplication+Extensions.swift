//
//  UIApplication+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import UIKit

extension UIApplication {
    var kWindow: UIWindow? {
        // keyWindow is deprecated
        UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    func rootViewController() -> UIViewController? {
        kWindow?.rootViewController
    }

    func showIndetermineHud() {
        kWindow?.showIndetermineHud()
    }

    func hideHud() {
        kWindow?.hideHud()
    }

    func openAppSettings() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier,
           let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier)
        {
            if canOpenURL(appSettings) {
                open(appSettings)
            }
        }
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
}
