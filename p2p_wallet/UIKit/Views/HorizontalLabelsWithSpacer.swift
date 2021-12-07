//
//  HorizontalLabelsWithSpacer.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 01.12.2021.
//

import BEPureLayout
import UIKit

final class HorizontalLabelsWithSpacer: BEView {
    private let leftLabel = UILabel()
    private let rightLabel = UILabel()

    func configureLeftLabel(configure: (UILabel) -> Void) {
        configure(leftLabel)
    }

    func configureRightLabel(configure: (UILabel) -> Void) {
        configure(rightLabel)
    }

    override func commonInit() {
        super.commonInit()

        layout()
    }

    private func layout() {
        addSubview(leftLabel)
        addSubview(rightLabel)

        leftLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)

        rightLabel.setContentHuggingPriority(.required, for: .horizontal)
        rightLabel.autoPinEdge(.leading, to: .trailing, of: leftLabel, withOffset: 8)
        rightLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
    }
}
