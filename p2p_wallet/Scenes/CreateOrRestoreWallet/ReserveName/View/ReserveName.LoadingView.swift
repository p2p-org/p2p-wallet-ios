//
//  ReserveName.LoadingView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 01.12.2021.
//

import UIKit

extension ReserveName {
    final class LoadingView: UIStackView {
        private let indicatorView = UIActivityIndicatorView()
            .withContentHuggingPriority(.required, for: .horizontal)
        private let label = UILabel(
            text: L10n.checkingNameSAvailability,
            textSize: 13,
            textColor: .textSecondary
        )

        init() {
            super.init(frame: .zero)

            axis = .horizontal
            spacing = 8
            alignment = .top

            addArrangedSubview(indicatorView)
            addArrangedSubview(label)

            indicatorView.startAnimating()
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
