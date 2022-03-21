//
//  FlexibleHeightVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation
import UIKit

class FlexibleHeightVC: BaseVStackVC, UIViewControllerTransitioningDelegate {
    var margin: UIEdgeInsets { .zero }

    // MARK: - Nested type

    class PresentationController: FlexibleHeightPresentationController {
        var roundedCorner: UIRectCorner?
        var cornerRadius: CGFloat = 20

        override func calculateFittingHeightOfPresentedView(targetWidth _: CGFloat) -> CGFloat {
            let vc = presentedViewController as! FlexibleHeightVC
            return vc.fittingHeightInContainer(frame: containerView!.frame)
        }

        override var frameOfPresentedViewInContainerView: CGRect {
            let vc = presentedViewController as! FlexibleHeightVC
            var frame = super.frameOfPresentedViewInContainerView
            frame.origin.x += vc.margin.left
            frame.size.width -= (vc.margin.left + vc.margin.right)
            return frame
        }

        override func containerViewDidLayoutSubviews() {
            super.containerViewDidLayoutSubviews()
            if let roundedCorner = roundedCorner {
                presentedView?.roundCorners(roundedCorner, radius: cornerRadius)
            }
        }
    }

    let position: FlexibleHeightPresentationController.Position
    init(position: FlexibleHeightPresentationController.Position) {
        self.position = position
        super.init()
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    func fittingHeightInContainer(frame: CGRect) -> CGFloat {
        scrollView.contentView
            .fittingHeight(targetWidth: frame.width - margin.left - margin.right - padding.left - padding.right) +
            scrollView.contentInset.top +
            scrollView.contentInset.bottom +
            margin.top +
            margin.bottom
    }

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source _: UIViewController
    ) -> UIPresentationController? {
        PresentationController(position: position, presentedViewController: presented, presenting: presenting)
    }
}
