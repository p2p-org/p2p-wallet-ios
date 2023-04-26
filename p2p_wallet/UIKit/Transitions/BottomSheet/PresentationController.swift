//
//  PresentationController.swift
//  p2p_wallet
//
//  Created by Ivan on 19.08.2022.
//

import UIKit
import Combine

class PresentationController: UIPresentationController {
    
    // Subjects
    private let dismissedSubject = PassthroughSubject<Void, Never>()
    var dismissed: AnyPublisher<Void, Never> { dismissedSubject.eraseToAnyPublisher() }
    
    override var shouldPresentInFullscreen: Bool { false }

    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = containerView!.bounds
        let halfHeight = bounds.height / 2
        return CGRect(
            x: 0,
            y: bounds.height - halfHeight,
            width: bounds.width,
            height: halfHeight
        )
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        containerView?.addSubview(presentedView!)
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    var driver: TransitionDriver!

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            driver.direction = .dismiss
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            dismissedSubject.send()
        }
    }
}
