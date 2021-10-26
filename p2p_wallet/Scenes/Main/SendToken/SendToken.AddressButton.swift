//
//  SendToken.AddressButton.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.10.2021.
//

import UIKit
import PureLayout

extension SendToken {

    enum AddressContentType {
        case empty
        case recipient(Recipient)
    }

    final class AddressButton: UIButton {

        var addressContent: AddressContentType = .empty {
            didSet {
                switch addressContent {
                case .empty:
                    setAddressIsEmpty(true)
                case let .recipient(recipient):
                    setAddressIsEmpty(false)
                    filledAddress.setRecipient(recipient)
                }
            }
        }
        private let addressPlaceholder = UILabel()

        private let walletIconView = UIImageView(width: 24, height: 24, image: .walletIcon, tintColor: .a3a5ba)
            .padding(.init(all: 10), backgroundColor: .white.onDarkMode(.h404040), cornerRadius: 12)

        private let filledAddress = RecipientView()

        init() {
            super.init(frame: .zero)

            configureSubviews()
            addSubviews()
            setConstraints()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func addSubviews() {
            [addressPlaceholder, filledAddress].forEach(addSubview)
        }

        private func setAddressIsEmpty(_ isEmpty: Bool) {
            addressPlaceholder.isHidden = !isEmpty
            filledAddress.isHidden = isEmpty
        }

        private func configureSubviews() {
            addressPlaceholder.text = L10n._0xESNOrP2pUsername
            addressPlaceholder.font = .systemFont(ofSize: 15)
            addressPlaceholder.textColor = UIColor.a3a5ba.onDarkMode(.h5887ff)

            filledAddress.isUserInteractionEnabled = false
        }

        private func setConstraints() {
            let placeholderConstraints = addressPlaceholder.autoPinEdgesToSuperviewEdges(
                with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            )
            let filledConstraints = filledAddress.autoPinEdgesToSuperviewEdges(
                with: .zero
            )

            NSLayoutConstraint.activate(placeholderConstraints + filledConstraints)
        }
    }
}
