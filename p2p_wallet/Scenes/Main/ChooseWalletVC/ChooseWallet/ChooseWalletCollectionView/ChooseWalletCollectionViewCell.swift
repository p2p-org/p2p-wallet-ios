//
//  ChooseWalletCollectionViewCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation

class ChooseWalletCollectionViewCell: WalletCell {
    override var loadingViews: [UIView] {super.loadingViews + [addressLabel]}
    lazy var addressLabel = UILabel(textSize: 13, textColor: .textSecondary)
    
    override func commonInit() {
        super.commonInit()
        stackView.alignment = .center
        stackView.constraintToSuperviewWithAttribute(.bottom)?
            .constant = -16
        
        coinNameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        coinNameLabel.numberOfLines = 1
        equityValueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        tokenCountLabel.font = .systemFont(ofSize: 13)
        
        stackView.addArrangedSubviews([
            coinLogoImageView,
            UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [coinNameLabel, equityValueLabel]),
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [addressLabel, tokenCountLabel])
            ])
        ])
    }
    
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        if let pubkey = item.pubkey {
            addressLabel.text = pubkey.prefix(4) + "..." + pubkey.suffix(4)
        } else {
            addressLabel.text = nil
        }
    }
}
