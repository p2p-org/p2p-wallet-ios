//
//  CMActionSheetPresentionController.swift
//  Commun
//
//  Created by Chung Tran on 4/23/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation
class FlexibleHeightPresentationController: DimmingPresentationController {
    // MARK: - Nested type
    enum Position {
        case bottom, center
    }
    
    let position: Position
    init(position: Position, presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        self.position = position
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    lazy var backingView = UIView(backgroundColor: .a4a4a4)
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else {return}
        containerView.addSubview(backingView)
        backingView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        backingView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
            .isActive = true
        super.presentationTransitionWillBegin()
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        backingView.isHidden = true
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let safeAreaFrame = safeAreaFrame else { return .zero }
        
        let targetWidth = safeAreaFrame.width
        
        let targetHeight = calculateFittingHeightOfPresentedView(targetWidth: targetWidth)
        
        var frame = safeAreaFrame
        
        if targetHeight > frame.size.height {
            return frame
        }
        
        switch position {
        case .bottom:
            frame.origin.y += frame.size.height - targetHeight
        case .center:
            frame.origin.y += (frame.size.height - targetHeight) / 2
        }
        
        frame.size.width = targetWidth
        frame.size.height = targetHeight + (containerView?.safeAreaInsets.bottom ?? 0)
        return frame
    }
    
    var safeAreaFrame: CGRect? {
        guard let containerView = containerView else { return nil }
        return containerView.bounds.inset(by: containerView.safeAreaInsets)
    }
    
    func calculateFittingHeightOfPresentedView(targetWidth: CGFloat) -> CGFloat {
        presentedView!.fittingHeight(targetWidth: targetWidth)
    }
}
