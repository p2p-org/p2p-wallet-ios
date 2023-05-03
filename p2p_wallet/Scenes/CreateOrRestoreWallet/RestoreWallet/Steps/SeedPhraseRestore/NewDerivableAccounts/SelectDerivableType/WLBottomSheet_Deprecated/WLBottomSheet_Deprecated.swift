//
//  WLBottomSheet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation

class WLBottomSheet: FlexibleHeightVC {
    init() {
        super.init(position: .bottom)
    }

    override func fittingHeightInContainer(frame: CGRect) -> CGFloat {
        let height = super.fittingHeightInContainer(frame: frame)
        return height + 30
    }

    override func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let pc = super.presentationController(
            forPresented: presented,
            presenting: presenting,
            source: source
        ) as! PresentationController
        pc.roundedCorner = [.topLeft, .topRight]
        pc.cornerRadius = 25
        return pc
    }

    override func setUp() {
        super.setUp()

        if let child = build() {
            stackView.addArrangedSubview(child)
        }
    }

    func build() -> UIView? { nil }
}

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

class BaseVStackVC: BaseVC {
    var padding: UIEdgeInsets { UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) }
    lazy var scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: padding)
    lazy var stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
    lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewDidTouch))
    
    override func setUp() {
        super.setUp()
        
        view.addGestureRecognizer(tapGesture)
        // scroll view for flexible height
        view.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        scrollView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
        
        // stackView
        scrollView.contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    @objc func viewDidTouch() {
        view.endEditing(true)
    }
}
