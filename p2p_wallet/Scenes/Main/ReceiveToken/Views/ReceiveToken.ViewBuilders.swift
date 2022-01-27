//
//  ReceiveToken.ViewBuilders.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2021.
//

import UIKit

extension ReceiveToken {
    static func textBuilder(text: NSAttributedString) -> UIStackView {
        UIStackView(axis: .horizontal, spacing: 10, alignment: .top, distribution: .fill) {
            UIView(width: 3, height: 3, backgroundColor: .textBlack, cornerRadius: 1.5)
                .padding(.init(x: 0, y: 8))
            UILabel(text: nil, textSize: 15, numberOfLines: 0)
                .withAttributedText(
                    text,
                    lineSpacing: 0
                ).withTag(1)
        }
    }
}
