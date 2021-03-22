//
//  CustomHeightPresentationController.swift
//  Commun
//
//  Created by Chung Tran on 11/25/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation

class CustomHeightPresentationController: DimmingPresentationController {
    /// height must be calculated base on device's orientation
    var height: () -> CGFloat
    
    /**
        Custom height PresentationController.

        - height: closure for calculating height base on environment, for example, deviceOrientation.
    */
    init?(height: @escaping () -> CGFloat, presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        self.height = height
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width, height: height() + 16)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        // 1
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerView!.bounds.size)
        
        // 2
        
        frame.origin.y = containerView!.frame.height - height() - 16
        
        return frame
    }
}
