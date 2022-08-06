//
//  ErrorView.swift
//  p2p_wallet
//
//  Created by Ivan on 25.04.2022.
//

import BEPureLayout
import Combine
import UIKit

extension History {
    class ErrorView: BEView {
        let tryAgainClicked = PassthroughSubject<Void, Never>()

        private var subscriptions = [AnyCancellable]()

        private let imageView = UIImageView(
            width: 80,
            height: 80,
            image: .transactionsError
        )
        private let titleLabel = UILabel(
            text: "\(L10n.sorry) :(",
            textSize: 22,
            weight: .medium,
            textAlignment: .center
        )
        private let descriptionLabel = UILabel(
            text: L10n.WeCouldnTUploadTheHistory.tryAgainLater,
            textSize: 14,
            textColor: .secondaryLabel,
            numberOfLines: 2,
            textAlignment: .center
        )
        private let actionButton = UIButton(
            height: 64,
            backgroundColor: ._5887ff,
            cornerRadius: 12,
            label: L10n.tryAgain,
            labelFont: .systemFont(ofSize: 17, weight: .bold)
        )

        override func commonInit() {
            super.commonInit()

            let stackView = UIStackView(axis: .vertical)
            stackView.spacing = 24
            let textStackView = UIStackView(axis: .vertical)
            textStackView.spacing = 12

            textStackView.addArrangedSubviews([titleLabel, descriptionLabel])
            stackView.addArrangedSubviews([imageView, textStackView])

            addSubview(stackView)
            addSubview(actionButton)

            NSLayoutConstraint.activate([
                actionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
                actionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])

            actionButton
                .onTap { [weak self] in
                    self?.tryAgainClicked.send()
                }
        }
    }
}
