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
                label.attributedText = NSMutableAttributedString()
                    .text(content.price, size: 15, color: .textBlack)
                    .text(" \(content.fiatPrice)", size: 15, color: .h8e8e93)
            }
        }

        private func layout() {
            addSubview(horizontalLabelsWithSpacer)
            horizontalLabelsWithSpacer.autoPinEdgesToSuperviewEdges()
        }
    }
}
