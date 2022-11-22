//
//  UIViewController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Combine
import Foundation
import SafariServices

extension UIViewController {
    @discardableResult
    func showAlert(
        title: String?,
        message: String?,
        buttonTitles: [String]? = nil,
        highlightedButtonIndex: Int? = nil,
        destroingIndex: Int? = nil,
        completion: ((Int) -> Void)? = nil
    ) -> UIAlertController {
        view.layer.removeAllAnimations()

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var allButtons = buttonTitles ?? [String]()
        if allButtons.isEmpty {
            allButtons.append(L10n.ok)
        }

        allButtons.enumerated().forEach { index, buttonTitle in
            let style: UIAlertAction.Style = index == destroingIndex ? .destructive : .default
            let action = UIAlertAction(title: buttonTitle, style: style, handler: { _ in
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

        if actions.isEmpty {
            alertController.view.tintColor = UIColor.black
            alertController.addAction(UIAlertAction(title: L10n.ok, style: .default))
        }

        for action in actions {
            alertController.addAction(action)
        }

        present(alertController, animated: true, completion: nil)
        return alertController
    }

    func showError(
        _ error: Error,
        showPleaseTryAgain: Bool = false,
        additionalMessage: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        let description = error.readableDescription
        let vc = tabBarController ?? navigationController ?? parent ?? self

        vc.showAlert(
            title: L10n.error.uppercaseFirst,
            message: description + (additionalMessage != nil ? "\n" + additionalMessage! : "") +
                (showPleaseTryAgain ? "\n" + L10n.pleaseTryAgainLater : ""),
            buttonTitles: [L10n.ok]
        ) { _ in
            completion?()
        }
    }

    func showErrorView(title: String? = nil, description: String? = nil, retryAction: (() -> Void)? = nil) {
        view.showErrorView(title: title, description: description, retryAction: retryAction)
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

    func showIndetermineHud(_: String? = nil) {
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

    func transition(
        from oldVC: UIViewController? = nil,
        to newVC: UIViewController,
        in containerView: UIView? = nil,
        completion: (() -> Void)? = nil
    ) {
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

// MARK: - ViewDidDisappearSwizzle

private var onCloseKey: UInt8 = 0
extension UIViewController {
    var onClose: (() -> Void)? {
        get {
            objc_getAssociatedObject(
                self,
                &onCloseKey
            ) as? () -> Void
        }
        set {
            objc_setAssociatedObject(
                self,
                &onCloseKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    @objc dynamic func viewDidDisappearOverride(_ animated: Bool) {
        viewDidDisappearOverride(animated) // Incase we need to override this method
        if isMovingFromParent || isBeingDismissed {
            onClose?()
        }
    }

    static func swizzleViewDidDisappear() {
        if self != UIViewController.self { return }
        let originalSelector = #selector(UIViewController.viewDidDisappear(_:))
        let swizzledSelector = #selector(UIViewController.viewDidDisappearOverride(_:))
        guard
            let originalMethod = class_getInstanceMethod(self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

// MARK: - ViewDidAppearSwizzle

extension UIViewController {
    static func swizzleViewDidAppear() {
        if self != UIViewController.self { return }
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledSelector = #selector(UIViewController.viewDidAppearOverride(_:))
        guard
            let originalMethod = class_getInstanceMethod(self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc dynamic func viewDidAppearOverride(_ animated: Bool) {
        viewDidAppearOverride(animated)
        // TODO: - Finish logic. We need to finish code for getting analyticId from UIViewControllers and SwiftUI Views
        guard let viewId = (UIApplication.topmostViewController() as? AnalyticView)?.analyticId else { return }
        ScreenAnalyticTracker.shared.setCurrentViewId(viewId)
    }
}
