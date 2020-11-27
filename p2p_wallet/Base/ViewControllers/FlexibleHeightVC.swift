//
//  FlexibleHeightVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation
import UIKit

class FlexibleHeightVC: BaseVStackVC, UIViewControllerTransitioningDelegate {
    // MARK: - Nested type
    class PresentationController: FlexibleHeightPresentationController {
        var roundedCorner: UIRectCorner?
        var cornerRadius: CGFloat = 20
        
        override func calculateFittingHeightOfPresentedView(targetWidth: CGFloat) -> CGFloat {
            let vc = presentedViewController as! FlexibleHeightVC
            return vc.fittingHeightInContainer(safeAreaFrame: safeAreaFrame!)
        }
        
        override func containerViewDidLayoutSubviews() {
            super.containerViewDidLayoutSubviews()
            if let roundedCorner = roundedCorner {
                presentedView?.roundCorners(roundedCorner, radius: cornerRadius)
            }
        }

    }
    
    let position: FlexibleHeightPresentationController.Position
    init(position: FlexibleHeightPresentationController.Position)
    {
        self.position = position
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fittingHeightInContainer(safeAreaFrame: CGRect) -> CGFloat {
        scrollView.contentView.fittingHeight(
            targetWidth: safeAreaFrame.width - padding.left - padding.right) /*+ scrollView.contentInset.top*/ + scrollView.contentInset.bottom
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(position: position, presentedViewController: presented, presenting: presenting)
    }
}
