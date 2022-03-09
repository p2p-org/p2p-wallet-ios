//
//  TransactionDetail.StatusView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation
import BEPureLayout
import UIKit
import RxCocoa
import SolanaSwift

extension TransactionDetail {
    final class StatusView: UIStackView {
        private let dotView = UIView(width: 8, height: 8, backgroundColor: .alertOrange, cornerRadius: 2)
        private let statusLabel = UILabel(text: L10n.pending.uppercaseFirst, textSize: 12, weight: .medium, textColor: .textSecondary)
        private let dateLabel = UILabel(text: "August 30, 2021 @ 12:51 PM", textSize: 15, textColor: .textSecondary, numberOfLines: 0)
        
        init() {
            super.init(frame: .zero)
            set(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                BEHStack(spacing: 5, alignment: .center, distribution: .fill) {
                    dotView
                    statusLabel
                }
                    .padding(.init(x: 9, y: 3.5), backgroundColor: .f6f6f8, cornerRadius: 4)
                dateLabel
            }
        }
        
        func driven(with driver: Driver<SolanaSDK.ParsedTransaction?>) -> TransactionDetail.StatusView {
            
            return self
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
