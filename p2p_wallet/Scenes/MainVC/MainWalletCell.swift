//
//  PriceCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class MainWalletCell: WalletCell {
    lazy var addressLabel = UILabel(text: "public key", textSize: 13, textColor: .textSecondary, numberOfLines: 1)
    
    override var loadingViews: [UIView] {
        super.loadingViews + [addressLabel]
    }
    
    override func commonInit() {
        super.commonInit()        
        equityValueLabel.font = .boldSystemFont(ofSize: 15)
        equityValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        tokenCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        let vStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
            row(arrangedSubviews: [coinNameLabel, equityValueLabel])
                .with(distribution: .fill),
            row(arrangedSubviews: [addressLabel, tokenCountLabel])
                .with(distribution: .fill)
        ])
        
        stackView.alignment = .center
        stackView.addArrangedSubviews([
            coinLogoImageView,
            vStackView
        ])
    }
    
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        if item.pubkey != nil {
            addressLabel.text = item.pubkeyShort()
        } else {
            addressLabel.text = nil
        }
    }
    
    private func row(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing)
        stackView.addArrangedSubviews(arrangedSubviews)
        return stackView
    }
}
