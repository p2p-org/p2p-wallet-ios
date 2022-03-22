//
//  OrcaSwapV2.ShowDetailsButton.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import PureLayout
import RxSwift
import UIKit

extension OrcaSwapV2 {
    final class ShowDetailsButton: UIButton {
        private let textLabel = UILabel(textSize: 15, weight: .regular)
        private let arrowView = UIImageView(width: 16, height: 16, tintColor: .textBlack)

        init() {
            super.init(frame: .zero)

            layout()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func layout() {
            let stackView = UIStackView(axis: .horizontal, spacing: 4) {
                textLabel
                arrowView
            }

            stackView.isUserInteractionEnabled = false

            addSubview(stackView)

            stackView.autoAlignAxis(toSuperviewAxis: .vertical)
            stackView.autoAlignAxis(toSuperviewAxis: .horizontal)
        }
    }
}
