//
//  UIViewController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import SafariServices
import Action

extension UIViewController {
    @discardableResult
    func showAlert(title: String?, message: String?, buttonTitles: [String]? = nil, highlightedButtonIndex: Int? = nil, destroingIndex: Int? = nil, completion: ((Int) -> Void)? = nil) -> UIAlertController {
        view.layer.removeAllAnimations()
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var allButtons = buttonTitles ?? [String]()
        if allButtons.count == 0 {
            allButtons.append("OK")
        }

        allButtons.enumerated().forEach { index, buttonTitle in
            let style: UIAlertAction.Style = index == destroingIndex ? .destructive : .default
            let action = UIAlertAction(title: buttonTitle, style: style, handler: { (_) in
                completion?(index)
            })
            alertController.addAction(action)
            // Check which button to highlight
            if index == highlightedButtonIndex {
                alertController.preferredAction = action
            }
        }
        present(alertController, animated: true, completion: nil)
        return alertController
    }
    
    @discardableResult
    func showAlert(title: String?, message: String?, actions: [UIAlertAction] = []) -> UIAlertController {
        view.layer.removeAllAnimations()
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if actions.count == 0 {
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
        }
        
        for action in actions {
            alertController.addAction(action)
        }
        
        present(alertController, animated: true, completion: nil)
        return alertController
    }
    
    func showError(_ error: Error, showPleaseTryAgain: Bool = false, additionalMessage: String? = nil, completion: (() -> Void)? = nil) {
        let description = error.readableDescription
        let vc = tabBarController ?? navigationController ?? parent ?? self
        
        vc.showAlert(title: L10n.error.uppercaseFirst, message: description + (additionalMessage != nil ? "\n" + additionalMessage! : "") + (showPleaseTryAgain ? "\n" + L10n.pleaseTryAgainLater : ""), buttonTitles: [L10n.ok]) { (_) in
            completion?()
        }
    }
    
    var errorView: ErrorView? {
        view.subviews.first(where: { $0 is ErrorView }) as? ErrorView
    }
    
    func showErrorView(error: Error?, retryAction: CocoaAction? = nil) {
        view.showErrorView(error: error, retryAction: retryAction)
    }
    
    func showErrorView(title: String? = nil, description: String? = nil, retryAction: CocoaAction? = nil) {
        view.showErrorView(title: title, description: description, retryAction: retryAction)
    }
    
    func removeErrorView() {
        view.removeErrorView()
    }
    
    func topViewController() -> UIViewController {
        if self.isKind(of: UITabBarController.self) {
            let tabbarController = self as! UITabBarController
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
    func showIndetermineHud(_ message: String? = nil) {
        view.showIndetermineHud()
    }
    
    func hideHud() {
        view.hideHud()
    }
    
    // MARK: - Keyboard
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - ChildVCs
    func add(child: UIViewController, to view: UIView? = nil) {
        guard child.parent == nil else {
            return
        }
        
        addChild(child)
        (view ?? self.view).addSubview(child.view)
        child.view.configureForAutoLayout()
        child.view.autoPinEdgesToSuperviewEdges()
        
        child.didMove(toParent: self)
    }
    
    func removeAllChilds() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    func transition(from oldVC: UIViewController? = nil, to newVC: UIViewController, in containerView: UIView? = nil, completion: (() -> Void)? = nil) {
        let oldVC = oldVC ?? children.last
        let containerView = containerView ?? view
        
        oldVC?.willMove(toParent: nil)
        oldVC?.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(newVC)
        containerView?.addSubview(newVC.view)
        newVC.view.configureForAutoLayout()
        newVC.view.autoPinEdgesToSuperviewEdges()
        
        newVC.view.alpha = 0
        newVC.view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3) {
            newVC.view.alpha = 1
            oldVC?.view.alpha = 0
        } completion: { _ in
            oldVC?.view.removeFromSuperview()
            oldVC?.removeFromParent()
            newVC.didMove(toParent: self)
            completion?()
        }
    }
    
    func forceResizeModal() {
        view.layoutIfNeeded()
        preferredContentSize.height += 1
    }
}
