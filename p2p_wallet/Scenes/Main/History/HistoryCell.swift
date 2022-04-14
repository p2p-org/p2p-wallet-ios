//
//  HistoryCell.swift
//  p2p_wallet
//
//  Created by Ivan on 13.04.2022.
//

import Foundation
import UIKit

extension History {
    final class Cell: TransactionCell {
        override var padding: UIEdgeInsets { .init(x: 20, y: 8) }

        override func commonInit() {
            super.commonInit()
            spacer = BEStackViewSpacing(0)
            transactionStatusIndicator.isHidden = true
            setupSkeleton()
        }

        private func setupSkeleton() {
            let topSpacer = UIView.spacer
            let bottomSpacer = UIView.spacer
            topStackView.insertArrangedSubview(topSpacer, at: 1)
            bottomStackView.insertArrangedSubview(bottomSpacer, at: 1)
        }
    }
}
