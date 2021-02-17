//
//  ResizablePresentationController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

class ExpandablePresentationController: DimmingPresentationController, ResizablePresentationController {
    // MARK: - Nested types
    enum CoverType {
        case full, haft
    }
    
    // MARK: - Properties
    var coverType = CoverType.haft
    var padding: UIEdgeInsets = .zero {
        didSet {
            (presentedViewController as? BaseVC)?.forceResizeModal()
        }
    }
    var currentTop: CGFloat?
    var minTop: CGFloat {
        containerView!.safeAreaInsets.top + padding.top
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard var frame = containerView?.bounds else { return .zero }
        guard let presentedViewFrame = presentedView?.frame else {return .zero}
        
        if let top = currentTop {
            if presentedViewFrame.origin.y < minTop {
                frame.origin.y = minTop
            } else {
                frame.origin.y = top
            }
        } else {
            var targetHeight: CGFloat = 0
            switch coverType {
            case .full:
                targetHeight = frame.height - minTop
            case .haft:
                targetHeight = frame.height / 2
            }
            frame.origin.y = frame.height - targetHeight
        }
        
        frame.size.height = frame.height - frame.origin.y
        return frame
    }
    
    var originalTop: CGFloat?
    func presentedViewDidSwipe(gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view else {return}
        
        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space.
        let translation = gestureRecognizer.translation(in: containerView)
        
        switch gestureRecognizer.state {
        case .began:
            // save original state
            originalTop = view.frame.origin.y
        case .changed:
            // on gesture changed
            currentTop = (originalTop ?? 0) + translation.y
            animateResizing = false
            (presentedViewController as? BaseVC)?.forceResizeModal()
        case .ended:
            // on gesture ended
            originalTop = nil
            
            // calculate distances
            let distanceToTop = abs(minTop - (currentTop ?? 0))
            let distanceToCenter = containerView!.frame.size.height / 2 - (currentTop ?? 0)
            let distanceToBottom = containerView!.bounds.height - (currentTop ?? 0)
            
            // Dismiss when presentedView is close to bottom
            if distanceToCenter < 0, distanceToBottom < abs(distanceToCenter) * 3 {
                presentedViewController
                    .dismiss(animated: true, completion: nil)
                return
            }
            
            // Define coverType
            if distanceToTop < abs(distanceToCenter) * 3 {
                coverType = .full
            } else {
                coverType = .haft
            }
            
            currentTop = nil
            animateResizing = true
            (presentedViewController as? BaseVC)?.forceResizeModal()
        default:
            originalTop = nil
            currentTop = nil
            animateResizing = true
            (presentedViewController as? BaseVC)?.forceResizeModal()
        }
    }
}
