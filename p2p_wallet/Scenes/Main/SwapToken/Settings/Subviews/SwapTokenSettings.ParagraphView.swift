//
//  SwapTokenSettings.ParagraphView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 22.12.2021.
//

import UIKit
import BEPureLayout

extension SwapTokenSettings {
    final class ParagraphView: BEView {
        private let pointView = UILabel(text: "·", textSize: 12, weight: .semibold, textColor: .h8e8e93)
        private let textLabel = UILabel(numberOfLines: 0)

        func setText(string: NSAttributedString) {
            textLabel.attributedText = string
        }

        init() {
            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()

            layout()
        }

        func layout() {
            addSubview(pointView)
            addSubview(textLabel)

            pointView.setContentHuggingPriority(.required, for: .horizontal)
            pointView.autoPinEdge(toSuperviewEdge: .top)
            pointView.autoPinEdge(toSuperviewEdge: .leading, withInset: 6)

            textLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
            textLabel.autoPinEdge(.leading, to: .trailing, of: pointView, withOffset: 6)
        }
    }
}
