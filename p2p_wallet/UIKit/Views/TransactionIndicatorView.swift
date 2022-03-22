//
//  TransactionIndicatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/04/2021.
//

import Foundation

class TransactionIndicatorView: BEView {
    public var percent: CGFloat = 0.0 {
        didSet {
            indicatorViewWidthConstraint = indicatorViewWidthConstraint?.setMultiplier(multiplier: percent)
            indicatorView.setNeedsLayout()
        }
    }

    override public var tintColor: UIColor! {
        didSet {
            indicatorView.backgroundColor = tintColor
        }
    }

    private lazy var indicatorView = UIView(backgroundColor: tintColor)
    private var indicatorViewWidthConstraint: NSLayoutConstraint?

    override func commonInit() {
        super.commonInit()

        addSubview(indicatorView)
        indicatorView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)

        indicatorViewWidthConstraint = indicatorView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0)

        indicatorViewWidthConstraint?.isActive = true
    }
}
