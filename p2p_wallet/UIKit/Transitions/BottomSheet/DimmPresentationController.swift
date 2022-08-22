//
//  DimmPresentationController.swift
//  p2p_wallet
//
//  Created by Ivan on 19.08.2022.
//

import Combine
import UIKit

class DimmPresentationController: PresentationController {
    private let subject = PassthroughSubject<Void, Never>()
    var dimmClicked: AnyPublisher<Void, Never> { subject.eraseToAnyPublisher() }

    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = containerView!.bounds
        return CGRect(
            x: 0,
            y: bounds.height - containerHeight,
            width: bounds.width,
            height: containerHeight
        )
    }

    var containerHeight: CGFloat = 0

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        containerView?.insertSubview(dimmView, at: 0)

        performAlongsideTransitionIfPossible { [unowned self] in
            dimmView.alpha = 1
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        dimmView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        dimmView.frame = containerView!.frame
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if !completed {
            dimmView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        performAlongsideTransitionIfPossible { [unowned self] in
            self.dimmView.alpha = 0
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            dimmView.removeFromSuperview()
        }
    }

    @objc func didTapView() {
        subject.send()
    }

    private func performAlongsideTransitionIfPossible(_ block: @escaping () -> Void) {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            block()
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            block()
        }, completion: nil)
    }

    private lazy var dimmView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.3)
        view.alpha = 0
        return view
    }()
}
