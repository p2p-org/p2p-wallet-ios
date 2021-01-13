//
//  WLModalPresentationController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

class WLModalPresentationController: DimmingPresentationController {
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
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard var frame = containerView?.bounds else { return .zero }
        
        // limitation
        let minTop = containerView!.safeAreaInsets.top + padding.top
        
        if let top = currentTop {
            if frame.origin.y < minTop {
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
