//
//  HistoryCell.swift
//  p2p_wallet
//
//  Created by Ivan on 13.04.2022.
//

import Foundation
import SolanaSwift
import TransactionParser
import UIKit

extension History {
    final class Cell: TransactionCell {
        override func commonInit() {
            super.commonInit()
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
