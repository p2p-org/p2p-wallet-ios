//
//  UIViewController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import SafariServices

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
        let description = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let vc = tabBarController ?? navigationController ?? parent ?? self
        
        vc.showAlert(title: L10n.error.uppercaseFirst, message: description + (additionalMessage != nil ? "\n" + additionalMessage! : "") + (showPleaseTryAgain ? "\n" + L10n.pleaseTryAgainLater : ""), buttonTitles: [L10n.ok]) { (_) in
            completion?()
        }
    }
    
    var errorView: ErrorView? {
        view.subviews.first(where: {$0 is ErrorView}) as? ErrorView
    }
    
    func showErrorView(error: Error) {
        view.showErrorView(error: error)
    }
    
    func showErrorView(title: String? = nil, description: String? = nil) {
        view.showErrorView(title: title, description: description)
    }
    
    func removeErrorView() {
        view.removeErrorView()
    }
    
    func topViewController() -> UIViewController {
        if self.isKind(of: UITabBarController.self) {
            let tabbarController =  self as! UITabBarController
            return tabbarController.selectedViewController!.topViewController()
        } else if self.isKind(of: UINavigationController.self) {
            let navigationController = self as! UINavigationController
            return navigationController.visibleViewController!.topViewController()
        } else if self.presentedViewController != nil {
            let controller = self.presentedViewController
            return controller!.topViewController()
        } else {
            return self.parent ?? self
        }
    }
    
    func showWebsite(url: String) {
        if let url = URL(string: url) {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let safariVC = SFSafariViewController(url: url, configuration: config)

            present(safariVC, animated: true)
        }
    }
    
    // MARK: - HUDs
    func showIndetermineHudWithMessage(_ message: String?) {
        view.showIndetermineHudWithMessage(message)
    }
    
    func hideHud() {
        view.hideHud()
    }
    
    // MARK: - Custom modal
    func presentCustomModal(vc wrappedVC: UIViewController, title: String? = nil, titleImageView: UIView? = nil) {
        let vc = DependencyContainer.shared.makeCustomModalVC(wrappedVC: wrappedVC, title: title, titleImageView: titleImageView)
        present(vc, animated: true, completion: nil)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
