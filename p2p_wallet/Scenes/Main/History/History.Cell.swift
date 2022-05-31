//
//  HistoryCell.swift
//  p2p_wallet
//
//  Created by Ivan on 13.04.2022.
//

import Foundation
import SolanaSwift
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

        override func setUp(with item: AnyHashable?) {
            super.setUp(with: item)
            guard let transaction = item as? SolanaSDK.ParsedTransaction else { return }

            switch transaction.value {
            case _ as SolanaSDK.SwapTransaction:
                amountInFiatLabel.text = amountInFiatLabel.text?.replacingOccurrences(of: "+", with: "")
                amountInFiatLabel.text = amountInFiatLabel.text?.replacingOccurrences(of: "-", with: "")
                amountInFiatLabel.textColor = .textBlack
            default:
                return
            }
        }
    }
}
