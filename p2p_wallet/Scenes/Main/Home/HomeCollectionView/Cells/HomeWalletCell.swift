//
//  HomeWalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import BECollectionView

class HomeWalletCell: EditableWalletCell {
    lazy var addressLabel = UILabel(text: "<public key>", textSize: 13, textColor: .textSecondary, numberOfLines: 1)
    lazy var indicatorColorView = UIView(width: 3, cornerRadius: 1.5)
    
    override func commonInit() {
        super.commonInit()
        coinNameLabel.font = .systemFont(ofSize: 17, weight: .medium)
        equityValueLabel.font = .systemFont(ofSize: 17, weight: .medium)
        equityValueLabel.textAlignment = .right
        equityValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        equityValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        tokenCountLabel.textAlignment = .right
        tokenCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        tokenCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let vStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
            UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                coinNameLabel
                equityValueLabel
            }
            UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                addressLabel
                tokenCountLabel
            }
        }
        
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
            addressLabel.text = item.shortPubkey()
        } else {
            addressLabel.text = nil
        }
        
        if item.amountInCurrentFiat == 0 {
            indicatorColorView.backgroundColor = .clear
        } else {
            indicatorColorView.backgroundColor = item.token.indicatorColor
        }
    }
    
    private func row(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing)
        stackView.addArrangedSubviews(arrangedSubviews)
        return stackView
    }
}

extension HomeWalletCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let wallet = item as? Wallet else {return}
        setUp(with: wallet)
    }
}
