//
//  OrcaSwapV2.DetailRatesView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import UIKit
import BEPureLayout

extension OrcaSwapV2 {
    final class DetailRatesView: BEView {
        private let horizontalLabelsWithSpacer = HorizontalLabelsWithSpacer()

        init() {
            super.init(frame: .zero)

            horizontalLabelsWithSpacer.configureLeftLabel { label in
                label.textColor = .h8e8e93
                label.font = .systemFont(ofSize: 15, weight: .regular)
            }

            layout()
        }

        func setData(content: RateRowContent) {
            horizontalLabelsWithSpacer.configureLeftLabel { label in
                label.text = L10n._1Price(content.token)
            }

            horizontalLabelsWithSpacer.configureRightLabel { label in
                let font: UIFont = .systemFont(ofSize: 15, weight: .regular)

                let resultString = NSMutableAttributedString()
                let priceString = NSAttributedString(
                    string: content.price,
                    attributes: [
                        .font: font,
                        .foregroundColor: UIColor.darkText
                    ]
                )

                resultString.append(priceString)

                let fiatPriceString = NSAttributedString(
                    string: " \(content.fiatPrice)",
                    attributes: [
                        .font: font,
                        .foregroundColor: UIColor.h8e8e93
                    ]
                )

                resultString.append(fiatPriceString)

                label.attributedText = resultString
            }
        }

        private func layout() {
            addSubview(horizontalLabelsWithSpacer)
            horizontalLabelsWithSpacer.autoPinEdgesToSuperviewEdges()
        }
    }
}
