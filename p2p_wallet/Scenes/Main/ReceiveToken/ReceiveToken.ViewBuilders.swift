//
//  ReceiveToken.ViewBuilders.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2021.
//

import UIKit

extension ReceiveToken {
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
    
    static func textBuilder(text: NSAttributedString) -> UIStackView {
        UIStackView(axis: .horizontal, spacing: 10, alignment: .top, distribution: .fill) {
            UIView(width: 3, height: 3, backgroundColor: .textBlack, cornerRadius: 1.5)
                .padding(.init(x: 0, y: 8))
            UILabel(text: nil, textSize: 15, numberOfLines: 0)
                .withAttributedText(
                    text,
                    lineSpacing: 8
                )
        }
    }
    
    static func copyAndShareableField(
        label: UILabel,
        copyTarget: Any?,
        copySelector: Selector,
        shareTarget: Any?,
        shareSelector: Selector
    ) -> UIView {
        UIStackView(axis: .horizontal, spacing: 4, alignment: .fill, distribution: .fill) {
            label
                .padding(.init(all: 20), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 4)
                .onTap(copyTarget, action: copySelector)
            
            UIImageView(width: 32, height: 32, image: .share, tintColor: .a3a5ba)
                .onTap(shareTarget, action: shareSelector)
                .padding(.init(all: 12), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 4)
        }
            .padding(.zero, cornerRadius: 12)
    }
    
    static func viewInExplorerButton(
        title: String,
        target: Any?,
        selector: Selector
    ) -> UIView {
        UILabel(text: title, textSize: 17, weight: .medium, textColor: .textSecondary, textAlignment: .center)
            .onTap(target, action: selector)
            .centeredHorizontallyView
            .padding(.init(x: 0, y: 9))
    }
}
