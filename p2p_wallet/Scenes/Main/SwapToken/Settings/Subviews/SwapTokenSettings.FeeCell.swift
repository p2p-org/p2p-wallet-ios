//
//  SwapTokenSettings.FeeCell.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.12.2021.
//

import BEPureLayout
import UIKit

extension SwapTokenSettings {
    final class FeeCell: UIStackView {
        private let image = CoinLogoImageView(size: 24, cornerRadius: 6, backgroundColor: .clear)
        private let tokenLabel = UILabel(textSize: 15, textColor: .textBlack)
        private let walletIcon = UIImageView(width: 12, height: 12, image: .newWalletIcon, tintColor: .h8e8e93)
        private let amountLabel = UILabel(textSize: 12, textColor: .h8e8e93)
        private let checkMarkImage = UIImageView(width: 14.3, height: 14.19, image: .tick)

        var onTapHandler: (() -> Void)?

        init() {
            super.init(frame: .zero)

            configureSelf()
            layout()
            onTap(self, action: #selector(handleTap))
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setIsSelected(_ isSelected: Bool) {
            checkMarkImage.isHidden = !isSelected
        }

        @discardableResult
        func setUp(content: FeeCellContent) -> Self {
            if let wallet = content.wallet {
                image.setUp(wallet: wallet)
                amountLabel.text = "\(wallet.amount.toString(maximumFractionDigits: 9))"
                walletIcon.isHidden = false
            } else {
                image.tokenIcon.image = nil
                amountLabel.text = nil
                walletIcon.isHidden = true
            }

            tokenLabel.text = content.tokenLabelText
            setIsSelected(content.isSelected)
            onTapHandler = content.onTapHandler

            return self
        }

        private func configureSelf() {
            axis = .horizontal
            distribution = .fill
            alignment = .center
            spacing = 8
        }

        private func layout() {
            [image, tokenLabel, walletIcon, amountLabel, checkMarkImage].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            tokenLabel.setContentHuggingPriority(.required, for: .horizontal)
            addArrangedSubviews {
                BEStackViewSpacing(10)
                image
                tokenLabel
                UIStackView(axis: .horizontal) {
                    walletIcon
                    amountLabel
                }
                checkMarkImage
                UIView(width: 10)
            }

            heightAnchor.constraint(equalTo: image.heightAnchor, constant: 36).isActive = true
        }

        @objc
        private func handleTap() {
            onTapHandler?()
        }
    }
}
