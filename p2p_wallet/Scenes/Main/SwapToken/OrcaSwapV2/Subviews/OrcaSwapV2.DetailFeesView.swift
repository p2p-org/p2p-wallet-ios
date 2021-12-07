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
            axis = .horizontal
            alignment = .top

            title.autoSetDimension(.height, toSize: 21)
            title.setContentHuggingPriority(.required, for: .horizontal)

            addArrangedSubviews {
                title
                feesDescriptionView
            }
        }

        private func createFeeLine(content: DetailedFeeContent) -> UIView {
            let label = UILabel()

            label.autoSetDimension(.height, toSize: 21)

            let font: UIFont = .systemFont(ofSize: 15, weight: .regular)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right

            let resultString = NSMutableAttributedString()
            let priceString = NSAttributedString(
                string: content.amount,
                attributes: [
                    .font: font,
                    .foregroundColor: UIColor.darkText
                ]
            )

            resultString.append(priceString)

            let reasonString = NSAttributedString(
                string: " (\(content.reason))",
                attributes: [
                    .font: font,
                    .foregroundColor: UIColor.h8e8e93
                ]
            )

            resultString.append(reasonString)
            resultString.addAttributes(
                [.paragraphStyle: paragraph],
                range: .init(location: 0, length: resultString.length)
            )

            label.attributedText = resultString

            return label
        }
    }
}
