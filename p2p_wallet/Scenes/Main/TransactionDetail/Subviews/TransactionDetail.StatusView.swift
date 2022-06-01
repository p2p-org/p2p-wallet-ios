//
//  TransactionDetail.StatusView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import BEPureLayout
import Foundation
import RxCocoa
import RxSwift
import SolanaSwift
import TransactionParser
import UIKit

extension TransactionDetail {
    final class StatusView: UIStackView {
        private let disposeBag = DisposeBag()
        private let dotView = UIView(width: 8, height: 8, backgroundColor: .alertOrange, cornerRadius: 2)
        private let statusLabel = UILabel(
            text: L10n.pending.uppercaseFirst,
            textSize: 12,
            weight: .medium,
            textColor: .textSecondary
        )
        private let dateLabel = UILabel(
            text: "August 30, 2021 @ 12:51 PM",
            textSize: 15,
            textColor: .textSecondary,
            numberOfLines: 0
        )

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

        func driven(with driver: Driver<ParsedTransaction?>) -> TransactionDetail.StatusView {
            driver
                .map { $0?.status.label }
                .drive(statusLabel.rx.text)
                .disposed(by: disposeBag)

            driver
                .map { $0?.status.indicatorColor }
                .drive(dotView.rx.backgroundColor)
                .disposed(by: disposeBag)

            driver
                .map { $0?.blockTime?.string(withFormat: "MMMM dd, yyyy @ HH:mm a") }
                .drive(dateLabel.rx.text)
                .disposed(by: disposeBag)

            return self
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
