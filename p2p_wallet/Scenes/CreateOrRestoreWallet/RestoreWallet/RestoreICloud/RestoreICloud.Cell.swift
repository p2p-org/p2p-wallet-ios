//
//  RestoreICloud.Cell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import BECollectionView
import Foundation

extension RestoreICloud {
    class Cell: BaseCollectionViewCell, BECollectionViewCell {
        override var padding: UIEdgeInsets { .init(x: 20, y: 9) }

        lazy var username = UILabel(text: "<top>", textSize: 13, weight: .medium, textColor: .textSecondary)
        lazy var privateKey = UILabel(text: "<bottom>", textSize: 15, weight: .medium)

        override func commonInit() {
            super.commonInit()

            stackView.layer.borderWidth = 1
            stackView.layer.borderColor = UIColor.f2f2f7.cgColor
            stackView.layer.cornerRadius = 12
            stackView.layer.applyShadow(color: UIColor.black, alpha: 0.05, x: 0, y: 1, blur: 8, spread: 0)

            stackView.layoutMargins = UIEdgeInsets(top: 15, left: 18, bottom: 15, right: 25)
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.axis = .horizontal
            stackView.alignment = .center

            let icon = UIImageView(image: .walletRoundedIcon)
            icon.autoSetDimensions(to: .init(width: 44, height: 44))

            stackView.addArrangedSubviews {
                icon
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    privateKey
                    username
                }
                UIView.defaultNextArrow()
            }

            stackView.autoSetDimension(.height, toSize: 72)
        }

        func setUp(with item: AnyHashable?) {
            guard let account = item as? ParsedAccount else { return }
            let pubkey = account.parsedAccount.publicKey.base58EncodedString.truncatingMiddle(numOfSymbolsRevealed: 12, numOfSymbolsRevealedInSuffix: 4)

            username.isHidden = false

            if let name = account.account.name {
                username.text = pubkey
                privateKey.text = name.withNameServiceDomain()
            } else {
                username.isHidden = true
                privateKey.text = pubkey
            }
        }
    }
}
