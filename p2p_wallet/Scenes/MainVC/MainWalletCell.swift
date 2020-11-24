//
//  PriceCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class MainWalletCell: WalletCell {
    lazy var graphView = UIImageView(width: 49, height: 15, image: .graphDemo)
    lazy var coinChangeLabel = UILabel(text: "0.35% 24 hrs", textSize: 13, textColor: .secondary)
    
    override var loadingViews: [UIView] {
        super.loadingViews + [equityValueLabel, coinChangeLabel, graphView]
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
        if let price = item.price {
            coinChangeLabel.isHidden = false
            coinChangeLabel.text = "\((price.change24h?.percentage * 100).toString(maximumFractionDigits: 2, showPlus: true))% 24 hrs"
        } else {
            coinChangeLabel.isHidden = true
        }
    }
    
    private func row(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing)
        stackView.addArrangedSubviews(arrangedSubviews)
        return stackView
    }
}
