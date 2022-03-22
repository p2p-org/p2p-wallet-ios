//
//  WLBalanceView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation

class WLBalanceView: BEView {
    lazy var walletView = UIImageView(width: 16, height: 16, image: .walletIcon)
    lazy var balanceLabel = UILabel(textSize: 13, weight: .medium)

    override var tintColor: UIColor! {
        didSet {
            self.walletView.tintColor = tintColor
            self.balanceLabel.textColor = tintColor
        }
    }

    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .horizontal, spacing: 5.33, alignment: .center, distribution: .fill) {
            walletView
            balanceLabel
        }
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()

        walletView.isHidden = true
    }
}
