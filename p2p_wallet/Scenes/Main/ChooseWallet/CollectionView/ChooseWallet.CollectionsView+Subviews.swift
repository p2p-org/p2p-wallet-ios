//
//  ChooseWallet.CollectionsView+Subviews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import Foundation
import BECollectionView

extension ChooseWallet.CollectionView {
    class Cell: WalletCell, BECollectionViewCell {
        lazy var addressLabel = UILabel(textSize: 13, textColor: .textSecondary)
        
        override func commonInit() {
            super.commonInit()
            stackView.addSubview(coinCheckMark)

            stackView.alignment = .center
            stackView.spacing = 12
            
            stackView.constraintToSuperviewWithAttribute(.trailing)?
                .constant = -18
            stackView.constraintToSuperviewWithAttribute(.leading)?
                .constant = 18
            stackView.constraintToSuperviewWithAttribute(.bottom)?
                .constant = -12
            stackView.constraintToSuperviewWithAttribute(.top)?
                .constant = 12
            
            coinSymbolLabel.font = .systemFont(ofSize: 17, weight: .medium)
            coinSymbolLabel.numberOfLines = 1
            equityValueLabel.font = .systemFont(ofSize: 17, weight: .medium)
            tokenCountLabel.font = .systemFont(ofSize: 13)
            
            stackView.addArrangedSubviews(
                [
                    coinLogoImageView,
                    UIStackView(
                        axis: .vertical,
                        spacing: 5,
                        alignment: .fill,
                        distribution: .fill,
                        arrangedSubviews: [
                            UIStackView(
                                axis: .horizontal,
                                spacing: 10,
                                alignment: .fill,
                                distribution: .equalSpacing,
                                arrangedSubviews: [coinSymbolLabel, equityValueLabel]
                            ),
                            UIStackView(
                                axis: .horizontal,
                                spacing: 10,
                                alignment: .fill,
                                distribution: .equalSpacing,
                                arrangedSubviews: [addressLabel, tokenCountLabel]
                            )
                        ]
                    )
                ]
            )

            coinCheckMark.autoAlignAxis(.horizontal, toSameAxisOf: coinLogoImageView)
            coinCheckMark.autoAlignAxis(.vertical, toSameAxisOf: coinLogoImageView)
        }
        
        override func setUp(with item: Wallet) {
            super.setUp(with: item)
            
            if item.token.isUndefined {
                addressLabel.text = L10n.unknownToken
            } else {
                addressLabel.text = item.token.name
            }
        }
        
        func setUp(with item: AnyHashable?) {
            guard let item = item as? Wallet else {return}
            setUp(with: item)
        }
    }
    
    class OtherTokenCell: Cell {
        override func setUp(with item: Wallet) {
            super.setUp(with: item)
            addressLabel.text = item.token.name
            
            equityValueLabel.isHidden = true
            tokenCountLabel.isHidden = true
        }
    }
}
