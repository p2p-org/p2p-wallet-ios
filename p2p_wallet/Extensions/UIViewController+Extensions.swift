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
        let message = error.localizedDescription
        let vc = tabBarController ?? navigationController ?? parent ?? self
        
        vc.showAlert(title: L10n.error.uppercaseFirst, message: message + (additionalMessage != nil ? "\n" + additionalMessage! : "") + (showPleaseTryAgain ? "\n" + L10n.pleaseTryAgainLater : ""), buttonTitles: [L10n.ok]) { (_) in
            completion?()
        }
    }
    
    var errorView: ErrorView? {
        view.subviews.first(where: {$0 is ErrorView}) as? ErrorView
    }
    
    func showErrorView(title: String? = nil, description: String? = nil) {
        removeErrorView()
        let errorView = ErrorView(backgroundColor: .textWhite)
        if let title = title {
            errorView.titleLabel.text = title
        }
        if let description = description {
            errorView.descriptionLabel.text = description
        }
        let spacer1 = UIView.spacer
        let spacer2 = UIView.spacer
        errorView.stackView.insertArrangedSubview(spacer1, at: 0)
        errorView.stackView.addArrangedSubview(spacer2)
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
        view.addSubview(errorView)
        errorView.autoPinEdgesToSuperviewEdges()
    }
    
    func removeErrorView() {
        view.subviews.filter {$0 is ErrorView}.forEach {$0.removeFromSuperview()}
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
    
    func presentTransactionVC() -> TransactionVC {
        let transactionVC = TransactionVC()
        present(transactionVC, animated: true, completion: nil)
        return transactionVC
    }
}
