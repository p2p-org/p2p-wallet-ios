//
//  Home.WalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import Foundation
import BECollectionView

extension Home {
    final class WalletCell: EditableWalletCell {
        lazy var coinFullnameLabel = UILabel(text: "<description>", textSize: 13, textColor: .textSecondary, numberOfLines: 1)
        lazy var indicatorColorView = UIView(width: 3, cornerRadius: 1.5)
        
        override func commonInit() {
            super.commonInit()
            coinSymbolLabel.font = .systemFont(ofSize: 17, weight: .medium)
            equityValueLabel.font = .systemFont(ofSize: 17, weight: .medium)
            equityValueLabel.textAlignment = .right
            equityValueLabel.setContentHuggingPriority(.required, for: .horizontal)
            equityValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            tokenCountLabel.textAlignment = .right
            tokenCountLabel.setContentHuggingPriority(.required, for: .horizontal)
            tokenCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            let vStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                    coinSymbolLabel
                    equityValueLabel
                }
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                    coinFullnameLabel
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
            if item.token.isUndefined {
                coinFullnameLabel.text = L10n.unknownToken
            } else {
                coinFullnameLabel.text = item.token.name
            }
            
            if item.amountInCurrentFiat == 0 {
                indicatorColorView.backgroundColor = .clear
            } else {
                indicatorColorView.backgroundColor = item.token.indicatorColor
            }
        }
    }
}

extension Home.WalletCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let wallet = item as? Wallet else {return}
        setUp(with: wallet)
    }
}
