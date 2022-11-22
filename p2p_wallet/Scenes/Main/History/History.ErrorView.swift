//
//  ErrorView.swift
//  p2p_wallet
//
//  Created by Ivan on 25.04.2022.
//

import BEPureLayout
import Combine
import UIKit
import KeyAppUI

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
        private let actionButton = TextButton(
            title: L10n.tryAgain,
            style: .primary,
            size: .large
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

            stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 0, relation: .greaterThanOrEqual)
            stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0, relation: .greaterThanOrEqual)
            stackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 0, relation: .greaterThanOrEqual)
            stackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 0, relation: .greaterThanOrEqual)
            stackView.autoCenterInSuperview()
            actionButton.autoPinEdgesToSuperviewSafeArea(with: .init(x: 16, y: 16), excludingEdge: .top)

            actionButton.onPressed { [weak self] _ in
                self?.tryAgainClicked.accept(())
            }
        }
    }
}
