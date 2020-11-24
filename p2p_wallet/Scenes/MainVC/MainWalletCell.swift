//
//  PriceCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class MainWalletCell: WalletCell {
    lazy var graphView = UIImageView(width: 49, height: 15, image: .graphDemo)
    
    override var loadingViews: [UIView] {
        super.loadingViews + [equityValueLabel, graphView]
    }
    
    override func commonInit() {
        super.commonInit()
        contentView.backgroundColor = .textWhite
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        let vStackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
            row(arrangedSubviews: [coinNameLabel, graphView]),
            row(arrangedSubviews: [equityValueLabel, coinPriceLabel]),
            row(arrangedSubviews: [tokenCountLabel, coinChangeLabel])
        ])
        
        stackView.addArrangedSubviews([
            coinLogoImageView,
            vStackView
        ])
    }
    
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        // TODO: Graph
    }
    
    private func row(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing)
        stackView.addArrangedSubviews(arrangedSubviews)
        return stackView
    }
}
