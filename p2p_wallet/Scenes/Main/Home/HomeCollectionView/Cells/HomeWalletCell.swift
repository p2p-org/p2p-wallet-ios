//
//  HomeWalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation

class HomeWalletCell: EditableWalletCell {
    lazy var addressLabel = UILabel(text: "<public key>", textSize: 13, textColor: .textSecondary, numberOfLines: 1)
    lazy var indicatorColorView = UIView(width: 3, cornerRadius: 1.5)
    
    override var loadingViews: [UIView] {
        super.loadingViews + [addressLabel]
    }
    
    override func commonInit() {
        super.commonInit()
        coinNameLabel.font = .systemFont(ofSize: 17, weight: .medium)
        equityValueLabel.font = .systemFont(ofSize: 17, weight: .medium)
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
            vStackView,
            indicatorColorView
        ])
        indicatorColorView.heightAnchor.constraint(equalTo: coinLogoImageView.heightAnchor)
            .isActive = true
    }
    
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        if item.pubkey != nil {
            addressLabel.text = item.pubkeyShort()
        } else {
            addressLabel.text = nil
        }
        
        if item.amountInUSD == 0 {
            indicatorColorView.backgroundColor = .clear
        } else {
            indicatorColorView.backgroundColor = item.indicatorColor
        }
    }
    
    private func row(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing)
        stackView.addArrangedSubviews(arrangedSubviews)
        return stackView
    }
}
