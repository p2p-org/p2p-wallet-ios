//
//  ResizablePresentationController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

class WLResizableModalVC: WLModalVC, UIViewControllerTransitioningDelegate {
    override init() {
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewDidSwipe(_:)))
        view.addGestureRecognizer(panGesture)
        view.isUserInteractionEnabled = true
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        ResizablePresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    var originalTop: CGFloat?
    @IBAction func viewDidSwipe(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.view != nil else {return}
        
        let presentationController = self.presentationController as! ResizablePresentationController
        
        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space.
        let translation = gestureRecognizer.translation(in: presentationController.containerView)
        
        switch gestureRecognizer.state {
        case .began:
            // save original state
            originalTop = view.frame.origin.y
        case .changed:
            // on gesture changed
            presentationController.currentTop = originalTop! + translation.y
            presentationController.animateResizing = false
            forceResizeModal()
        case .ended:
            // on gesture ended
            originalTop = nil
            
            // calculate distances
            let distanceToTop = abs(presentationController.minTop - presentationController.currentTop!)
            let distanceToCenter = abs(presentationController.containerView!.frame.size.height / 2 - presentationController.currentTop!)
            let distanceToBottom = abs(presentationController.containerView!.bounds.height - presentationController.currentTop!)
            
            // Dismiss when presentedView is close to bottom
            if distanceToBottom < distanceToCenter {
                dismiss(animated: true, completion: nil)
                return
            }
            
            // Define coverType
            if distanceToTop > distanceToCenter{
                presentationController.coverType = .haft
            } else {
                presentationController.coverType = .full
            }
            
            presentationController.currentTop = nil
            presentationController.animateResizing = true
            forceResizeModal()
        default:
            originalTop = nil
            presentationController.currentTop = nil
            presentationController.animateResizing = true
            forceResizeModal()
        }
    }
}

class ResizablePresentationController: DimmingPresentationController {
    // MARK: - Nested types
    enum CoverType {
        case full, haft
    }
    
    // MARK: - Properties
    var resizable = true
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
}
