//
//  CMActionSheetPresentionController.swift
//  Commun
//
//  Created by Chung Tran on 4/23/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation

class FlexibleHeightPresentationController: DimmingPresentationController, ResizablePresentationController {
    // MARK: - Nested type

    enum Position {
        case bottom, center
    }

    // MARK: - Properties

    let position: Position
    var presentedViewFixedFrame: CGRect?
    var presentedViewCurrentTop: CGFloat?

    // MARK: - Initializer

    init(
        position: Position,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.position = position
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    // MARK: - Methods

    override var frameOfPresentedViewInContainerView: CGRect {
        guard var frame = containerView?.bounds else { return .zero }

        let targetWidth = frame.width
        var targetHeight: CGFloat

        // if swipe gesture is being called
        if position == .bottom,
           let currentTop = presentedViewCurrentTop,
           let fixedFrame = presentedViewFixedFrame,
           currentTop > fixedFrame.origin.y
        {
            frame.origin.y = currentTop
            targetHeight = fixedFrame.height
        }

        // if no geture is being called
        else {
            targetHeight = calculateFittingHeightOfPresentedView(targetWidth: targetWidth)

            if targetHeight > frame.size.height {
                return frame
            }

            switch position {
            case .bottom:
                frame.origin.y += frame.size.height - targetHeight
            case .center:
                frame.origin.y += (frame.size.height - targetHeight) / 2
            }
        }

        frame.size.width = targetWidth
        frame.size.height = targetHeight
        return frame
    }

    func calculateFittingHeightOfPresentedView(targetWidth: CGFloat) -> CGFloat {
        if let height = presentedViewFixedFrame?.height { return height }
        return presentedView!.fittingHeight(targetWidth: targetWidth)
    }

    func presentedViewDidSwipe(gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view else { return }

        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space.
        let translation = gestureRecognizer.translation(in: containerView)

        switch gestureRecognizer.state {
        case .began:
            // save original state
            presentedViewFixedFrame = view.frame

        case .changed:
            // on gesture changed
            presentedViewCurrentTop = presentedViewFixedFrame!.origin.y + translation.y
            animateResizing = false
            (presentedViewController as? BaseVC)?.forceResizeModal()
        case .ended:
            // calculate distances
            if let presentedViewCurrentTop = presentedViewCurrentTop,
               let presentedViewFixedFrame = presentedViewFixedFrame
            {
                let distanceToBottom = abs(containerView!.bounds.height - presentedViewCurrentTop)
                let distanceToTop = abs(presentedViewFixedFrame.origin.y - presentedViewCurrentTop)
                if distanceToBottom < distanceToTop * 5 {
                    presentedViewController
                        .dismiss(animated: true, completion: nil)
                    return
                }
            }

            // Dismiss when presentedView is close to bottom
            presentedViewCurrentTop = nil
            animateResizing = true
            (presentedViewController as? BaseVC)?.forceResizeModal()

            presentedViewFixedFrame = nil
        default:
            presentedViewCurrentTop = nil
            animateResizing = true
            (presentedViewController as? BaseVC)?.forceResizeModal()
            presentedViewFixedFrame = nil
        }
    }
}
