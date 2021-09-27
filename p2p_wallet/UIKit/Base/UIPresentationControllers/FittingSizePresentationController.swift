//
//  FittingSizePresentationController.swift
//  Commun
//
//  Created by Chung Tran on 11/25/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation

class FittingSizePresentationController: DimmingPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView,
            let presentedView = presentedView else {return .zero}
        
        let inset: CGFloat = 0
        
        let safeAreaFrame = containerView.bounds
            .inset(by: containerView.safeAreaInsets)
        
        let targetWidth = safeAreaFrame.width - 2 * inset
        
        let fittingSize = CGSize(
            width: targetWidth,
            height: UIView.layoutFittingCompressedSize.height
        )
        
        let targetHeight = presentedView.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow).height
        
        var frame = safeAreaFrame
        frame.origin.x += inset
        frame.origin.y += frame.size.height - targetHeight - inset
        frame.size.width = targetWidth
        frame.size.height = targetHeight + containerView.safeAreaInsets.bottom
        
        return frame
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}
