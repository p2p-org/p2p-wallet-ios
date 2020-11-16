//
//  CMActionSheetPresentionController.swift
//  Commun
//
//  Created by Chung Tran on 4/23/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation
class FlexibleHeightPresentationController: DimmingPresentationController {
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
        
        frame.origin.y += frame.size.height - targetHeight
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
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedView?.roundCorners([.topLeft, .topRight], radius: 20)
    }
}
