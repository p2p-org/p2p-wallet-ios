//
//  OrcaSwap2.ClickableRow.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 06.12.2021.
//

import BEPureLayout
import UIKit

extension OrcaSwapV2 {
    final class ClickableRow: UIStackView {
        private let horizontalLabelsWithSpacer = HorizontalLabelsWithSpacer()
        var clickHandler: (() -> Void)?

        init(title: String) {
            super.init(frame: .zero)

            horizontalLabelsWithSpacer.configureLeftLabel { label in
                label.textColor = .h8e8e93
                label.text = title
                label.font = .systemFont(ofSize: 15, weight: .regular)
            }

            horizontalLabelsWithSpacer.configureRightLabel { label in
                label.textColor = .textBlack
                label.font = .systemFont(ofSize: 15, weight: .regular)
            }

            layout()
            onTap(self, action: #selector(didTap))
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setValue(text: String?) {
            horizontalLabelsWithSpacer.configureRightLabel { label in
                label.text = text
            }
        }

        private func layout() {
            axis = .horizontal
            alignment = .center
            spacing = 4

            addArrangedSubviews {
                horizontalLabelsWithSpacer
                UIView.defaultNextArrow()
            }
        }

        @objc
        private func didTap() {
            clickHandler?()
        }
    }
}
