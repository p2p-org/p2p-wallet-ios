//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class RecipientView: UIStackView {
        private let recipientIcon = UIImageView()
        private let textFieldsStackView = UIStackView(
            axis: .vertical,
            spacing: 8,
            alignment: .leading,
            distribution: .equalSpacing
        )
        private let titleLabel = UILabel(text: "<recipientName>", textSize: 17, weight: .semibold)
        private let descriptionLabel: UILabel = {
            let label = UILabel(text: "<recipientAddress>", textSize: 15, weight: .regular, textColor: .textSecondary)
            label.lineBreakMode = .byTruncatingMiddle
            return label
        }()

        init() {
            super.init(frame: .zero)

            configureSelf()
            configureSubviews()
            addSubviews()
            setConstraints()
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setRecipient(_ recipient: SendToken.Recipient) {
            titleLabel.text = recipient.name ?? recipient.address.truncatingMiddle(
                numOfSymbolsRevealed: 13,
                numOfSymbolsRevealedInSuffix: 4
            )
            recipientIcon.image = .emptyUserAvatar
            descriptionLabel.textColor = .textSecondary
            if recipient.name == nil {
                let shouldShowDescriptionLabel = recipient.hasNoFunds || recipient.hasNoInfo
                descriptionLabel.isHidden = !shouldShowDescriptionLabel
                if shouldShowDescriptionLabel {
                    descriptionLabel.text = recipient.hasNoFunds ? L10n.cautionThisAddressHasNoFunds : L10n
                        .couldNotRetrieveAccountInfo
                    recipientIcon.image = .warningUserAvatar
                    descriptionLabel.textColor = .ff9500
                }
            } else {
                descriptionLabel.isHidden = false
                descriptionLabel.text = recipient.address
            }
        }

        func setHighlighted() {
            recipientIcon.image = .emptyUserAvatarHighlighted
        }

        private func configureSelf() {
            axis = .horizontal
            spacing = 12
            alignment = .center
            distribution = .fill
        }

        private func configureSubviews() {
            recipientIcon.image = .emptyUserAvatar
            [titleLabel, descriptionLabel].forEach(textFieldsStackView.addArrangedSubview)
        }

        private func addSubviews() {
            [recipientIcon, textFieldsStackView].forEach(addArrangedSubview)
        }

        private func setConstraints() {
            recipientIcon.autoSetDimensions(to: CGSize(width: 45, height: 45))
        }
    }
}
