//
//  HalfSizePresentationController.swift
//  Commun
//
//  Created by Chung Tran on 9/30/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import UIKit

class HalfSizePresentationController: DimmingPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        // 1        
        var frame: CGRect = .zero
        
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerView!.bounds.size)
        
        // 2
        frame.origin.y = containerView!.frame.size.height - frame.size.height
        
        return frame
    }
    
    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation == .landscapeLeft ||
            UIDevice.current.orientation == .landscapeRight
        {
            return CGSize(width: parentSize.width, height: parentSize.height)
        }
        return CGSize(width: parentSize.width, height: parentSize.height*(2.0/3.0))
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.roundCorners([.topLeft, .topRight], radius: 20)
    }
}
