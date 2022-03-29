//
//  ReceiveToken.ExplorerButton.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 01.02.2022.
//

import PureLayout
import UIKit

extension ReceiveToken {
    final class ExplorerButton: UIButton {
        private lazy var stackView = UIStackView(
            axis: .horizontal,
            spacing: 4.adaptiveHeight,
            alignment: .center,
            distribution: .fill
        ) {
            label
            realImageView
        }

        private let realImageView = UIImageView(
            width: 16,
            height: 16,
            image: .externalLink.withRenderingMode(.alwaysTemplate),
            tintColor: .textBlack
        )
        private let label = UILabel(
            textSize: 15.adaptiveHeight,
            textColor: .textBlack,
            textAlignment: .center
        )
            .withContentCompressionResistancePriority(.required, for: .horizontal)

        init(title: String) {
            super.init(frame: .zero)

            label.text = title

            autoSetDimension(.height, toSize: 56.adaptiveHeight)

            addSubview(stackView)
            stackView.autoCenterInSuperview()
            stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 0, relation: .greaterThanOrEqual)
            stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0, relation: .greaterThanOrEqual)
            stackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 16, relation: .greaterThanOrEqual)
            stackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16, relation: .greaterThanOrEqual)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
