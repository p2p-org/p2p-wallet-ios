//
//  OrcaSwapV2.DetailFeesView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import BEPureLayout
import UIKit

extension OrcaSwapV2 {
    final class DetailFeesView: UIStackView {
        private let title = UILabel(
            text: L10n.swapFees,
            textSize: 15,
            weight: .regular,
            textColor: .h8e8e93
        )
        private let feesDescriptionView = UIStackView(
            axis: .vertical,
            spacing: 8,
            alignment: .fill
        )

        init() {
            super.init(frame: .zero)

            layout()
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setData(content: DetailedFeesContent) {
            feesDescriptionView.arrangedSubviews.forEach {
                $0.removeFromSuperview()
            }

            content.parts.forEach {
                feesDescriptionView.addArrangedSubview(createFeeLine(content: $0))
            }

            if let total = content.total {
                feesDescriptionView.addArrangedSubviews {
                    UIView.defaultSeparator()
                    createFeeLine(
                        content: .init(
                            amount: total,
                            reason: L10n.totalFee
                        )
                    )
                }
            }
        }

        private func layout() {
            set(axis: .horizontal, spacing: 8, alignment: .top)

            title.autoSetDimension(.height, toSize: 21)
            title.setContentHuggingPriority(.required, for: .horizontal)

            addArrangedSubviews {
                title
                feesDescriptionView
            }
        }

        private func createFeeLine(content: DetailedFeeContent) -> UIView {
            let label = UILabel(text: nil, textSize: 15, numberOfLines: 0, textAlignment: .right)
            
            label.attributedText = NSMutableAttributedString()
                .text(content.amount, size: 15, color: .textBlack)
                .text(" (\(content.reason))", size: 15, color: .h8e8e93)
                .withParagraphStyle(minimumLineHeight: 21, lineSpacing: 4, alignment: .right)

            return label
        }
    }
}
