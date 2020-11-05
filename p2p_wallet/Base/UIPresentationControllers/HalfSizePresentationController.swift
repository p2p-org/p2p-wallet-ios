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
        frame.origin.y = containerView!.frame.height*(1.0/3.0)
        
        return frame
    }
    
    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width, height: parentSize.height*(2.0/3.0))
    }
}
