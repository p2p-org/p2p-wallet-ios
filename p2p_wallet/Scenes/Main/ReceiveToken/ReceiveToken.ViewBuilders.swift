//
//  ReceiveToken.ViewBuilders.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2021.
//

import Foundation

extension ReceiveToken {
    static func switchField(text: String, switch: UISwitch) -> UIView {
        UIStackView(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill) {
            UILabel(text: text, textSize: 15, weight: .semibold, numberOfLines: 0)
            `switch`
                .withContentHuggingPriority(.required, for: .horizontal)
        }
            .padding(.init(all: 20), cornerRadius: 12)
            .border(width: 1, color: .f6f6f8.onDarkMode(.white.withAlphaComponent(0.5)))
    }

    static func textBuilder(text: String) -> UIStackView {
        UIStackView(axis: .horizontal, spacing: 10, alignment: .top, distribution: .fill) {
            UIView(width: 3, height: 3, backgroundColor: .textBlack, cornerRadius: 1.5)
                .padding(.init(x: 0, y: 8))
            UILabel(text: nil, textSize: 15, numberOfLines: 0)
                .withAttributedText(
                    NSMutableAttributedString()
                        .text(text, size: 15),
                    lineSpacing: 8
                )
        }
    }
}
