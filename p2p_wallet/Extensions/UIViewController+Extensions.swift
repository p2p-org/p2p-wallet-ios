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
        let description = error.readableDescription
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
        let vc = makeCustomModalVC(wrappedVC: wrappedVC, title: title, titleImageView: titleImageView)
        present(vc, animated: true, completion: nil)
    }
    
    func makeCustomModalVC(wrappedVC: UIViewController, title: String? = nil, titleImageView: UIView? = nil) -> WLModalWrapperVC {
        let vc = WLModalWrapperVC(wrapped: wrappedVC)
        vc.title = title
        vc.titleImageView = titleImageView
        vc.modalPresentationStyle = wrappedVC.modalPresentationStyle
        vc.transitioningDelegate = wrappedVC as? UIViewControllerTransitioningDelegate
        return vc
    }
    
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
    
    func transition(from oldVC: UIViewController? = nil, to newVC: UIViewController, in containerView: UIView? = nil) {
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
        }
    }
}
