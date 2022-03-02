//
//  SupportedTokens.CollectionViewCell.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.01.2022.
//

import BECollectionView
import SolanaSwift
import UIKit

extension SupportedTokens.CollectionView {
    final class Cell: BaseCollectionViewCell, BECollectionViewCell {
        private let coinLogoImageView = CoinLogoImageView(size: 45)
        private let coinFullnameLabel = UILabel(
            text: "<Coin name>",
            textSize: 14,
            weight: .medium,
            textColor: .h202020.onDarkMode(.white),
            numberOfLines: 0
        )
        private let coinSymbolLabel = UILabel(
            text: "<Coin name>",
            textSize: 14,
            weight: .bold,
            textColor: .h202020.onDarkMode(.white),
            numberOfLines: 0
        )

        override func commonInit() {
            super.commonInit()

            coinSymbolLabel.setContentHuggingPriority(.required, for: .horizontal)
            stackView.axis = .horizontal
            stackView.spacing = 12.adaptiveWidth
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.addArrangedSubviews {
                coinLogoImageView
                coinFullnameLabel
                coinSymbolLabel
            }

            stackView.constraintToSuperviewWithAttribute(.trailing)?.constant = -18
            stackView.constraintToSuperviewWithAttribute(.leading)?.constant = 18
            stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -12
            stackView.constraintToSuperviewWithAttribute(.top)?.constant = 12
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            coinLogoImageView.tokenIcon.cancelPreviousTask()
            coinLogoImageView.tokenIcon.image = nil
        }

        func setUp(with item: SolanaSDK.Token) {
            coinLogoImageView.setUp(token: item)
            coinSymbolLabel.text = item.symbol.isEmpty
                ? item.address.prefix(4) + "..." + item.address.suffix(4)
                : item.symbol
            coinFullnameLabel.text = item.symbol == "SOL" ? L10n.solana : item.name
        }

        lazy var addressLabel = UILabel(textSize: 13, textColor: .textSecondary)

        func setUp(with item: AnyHashable?) {
            guard let item = item as? SolanaSDK.Token else {return}
            setUp(with: item)
        }
    }
}
