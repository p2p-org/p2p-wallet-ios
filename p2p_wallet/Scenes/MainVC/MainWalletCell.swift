//
//  PriceCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class MainWalletCell: WalletCell {
    lazy var addressLabel = UILabel(text: "public key", textSize: 13, textColor: .secondary, numberOfLines: 1)
    
    override var loadingViews: [UIView] {
        super.loadingViews + [addressLabel]
    }
    
    override func commonInit() {
        super.commonInit()
        contentView.backgroundColor = .textWhite
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        coinPriceLabel.font = .boldSystemFont(ofSize: 15)
        coinPriceLabel.setContentHuggingPriority(.required, for: .horizontal)
        tokenCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        let vStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
            row(arrangedSubviews: [coinNameLabel, coinPriceLabel])
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
        if let pubkey = item.pubkey {
            addressLabel.text = "0x" + pubkey.prefix(4) + "..." + pubkey.suffix(4)
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
