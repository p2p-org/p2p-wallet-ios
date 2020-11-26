//
//  UIViewController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

extension UIViewController {
    @discardableResult
    func showAlert(title: String?, message: String?, buttonTitles: [String]? = nil, highlightedButtonIndex: Int? = nil, completion: ((Int) -> Void)? = nil) -> UIAlertController {
        view.layer.removeAllAnimations()
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var allButtons = buttonTitles ?? [String]()
        if allButtons.count == 0 {
            allButtons.append("OK")
        }

        for index in 0..<allButtons.count {
            let buttonTitle = allButtons[index]
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: { (_) in
                completion?(index)
            })
            alertController.addAction(action)
            // Check which button to highlight
            if let highlightedButtonIndex = highlightedButtonIndex, index == highlightedButtonIndex {
                alertController.preferredAction = action
            }
        }
        present(alertController, animated: true, completion: nil)
        return alertController
    }
    
    func showError(_ error: Error, showPleaseTryAgain: Bool = false, additionalMessage: String? = nil, completion: (() -> Void)? = nil) {
        let message = error.localizedDescription
        let vc = tabBarController ?? navigationController ?? parent ?? self
        
        vc.showAlert(title: L10n.error.uppercaseFirst, message: message + (additionalMessage != nil ? "\n" + additionalMessage! : "") + (showPleaseTryAgain ? "\n" + L10n.pleaseTryAgainLater : ""), buttonTitles: [L10n.ok]) { (_) in
            completion?()
        }
    }
    
    func topViewController() -> UIViewController {
        if self.isKind(of: UITabBarController.self) {
            let tabbarController =  self as! UITabBarController
            return tabbarController.selectedViewController!.topViewController()
        } else if (self.isKind(of: UINavigationController.self)) {
            let navigationController = self as! UINavigationController
            return navigationController.visibleViewController!.topViewController()
        } else if ((self.presentedViewController) != nil){
            let controller = self.presentedViewController
            return controller!.topViewController()
        } else {
            return self.parent ?? self
        }
    }
}
