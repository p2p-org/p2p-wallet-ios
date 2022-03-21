//
//  DimmingPresentationController.swift
//  Commun
//
//  Created by Chung Tran on 10/1/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    // MARK: - Properties

    var dimmingView: UIView!
    var animateResizing = true

    // MARK: - Class Initialization

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        setupDimmingView()
    }

    override func presentationTransitionWillBegin() {
        guard let dimmingView = dimmingView else {
            return
        }

        // 1
        containerView?.insertSubview(dimmingView, at: 0)

        // 2
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView])
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView])
        )

        // 3
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }

    // MARK: - Class Functions

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }

    // MARK: - Custom Functions

    func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmingView.alpha = 0.0

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        dimmingView.addGestureRecognizer(recognizer)
    }

    // MARK: - Actions

    @objc func handleTap(recognizer _: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }

    // MARK: - Events

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        containerView?.setNeedsLayout()
        containerView?.subviews.forEach { $0.layoutIfNeeded() }
        if animateResizing {
            UIView.animate(withDuration: 0.3) {
                self.containerView?.layoutIfNeeded()
            }
        } else {
            containerView?.layoutIfNeeded()
        }
    }
}
