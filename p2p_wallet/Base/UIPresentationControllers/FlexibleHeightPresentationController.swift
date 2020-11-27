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
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard var frame = containerView?.bounds else { return .zero }
        
        let targetWidth = frame.width
        
        let targetHeight = calculateFittingHeightOfPresentedView(targetWidth: targetWidth)
        
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
        frame.size.height = targetHeight
        return frame
    }
    
    func calculateFittingHeightOfPresentedView(targetWidth: CGFloat) -> CGFloat {
        presentedView!.fittingHeight(targetWidth: targetWidth)
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        UIView.animate(withDuration: 0.3) {
            self.containerView?.setNeedsLayout()
            self.containerView?.layoutIfNeeded()
        }
    }
}
