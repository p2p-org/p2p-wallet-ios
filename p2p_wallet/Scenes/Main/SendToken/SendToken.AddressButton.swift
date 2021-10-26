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
        case address(AddressContent)
    }

    struct AddressContent {
        let address: String
        let p2pName: String?
        let image: UIImage?
    }

    final class AddressButton: UIButton {

        var addressContent: AddressContentType = .empty {
            didSet {
                switch addressContent {
                case .empty:
                    setEmptyAddress()
                case .address(_):
                    assertionFailure()
                }
            }
        }
        private let addressPlaceholder = UILabel()

        private let walletIconView = UIImageView(width: 24, height: 24, image: .walletIcon, tintColor: .a3a5ba)
            .padding(.init(all: 10), backgroundColor: .white.onDarkMode(.h404040), cornerRadius: 12)

        private let filledAddress = UIStackView(
            axis: .horizontal,
            spacing: 10,
            alignment: .center,
            distribution: .fill
        )

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

        private func setEmptyAddress() {
            addressPlaceholder.isHidden = false
            filledAddress.isHidden = true
        }

        private func configureSubviews() {
            addressPlaceholder.text = L10n._0xESNOrP2pUsername
            addressPlaceholder.font = .systemFont(ofSize: 15)
            addressPlaceholder.textColor = UIColor.a3a5ba.onDarkMode(.h5887ff)
        }

        private func setConstraints() {
            let placeholderConstraints = addressPlaceholder.autoPinEdgesToSuperviewEdges(
                with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            )
            let filledConstraints = filledAddress.autoPinEdgesToSuperviewEdges(
                with: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            )

            NSLayoutConstraint.activate(placeholderConstraints + filledConstraints)
        }
    }
}
