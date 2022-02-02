//
//  OrcaSwapV2.DetailFeesView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

extension OrcaSwapV2 {
    final class DetailFeesView: BECompositionView {
        private let feesDriver: Driver<Loadable<[PayingFee]>>
        private let disposeBag = DisposeBag()

        init(feesDriver: Driver<Loadable<[PayingFee]>>) {
            self.feesDriver = feesDriver
            super.init()
        }

        override func build() -> UIView {
            BEBuilder(driver: feesDriver) { [weak self] snapshot in
                guard let self = self else { return UIView() }

                switch snapshot.state {
                case .loaded:
                    let value = snapshot.value ?? []
                    let group = Dictionary(grouping: value, by: { $0.type.headerString })

                    return BEVStack {
                        // Fee categories
                        for (header, fees) in group {
                            self.row(title: header, descriptions: fees.map { self.formatAmount(fee: $0) })
                        }
                        // Separator
                        if value.count > 0 { UIView.defaultSeparator().padding(.init(only: .bottom, inset: 12)) }
                        // Total
                        BEHStack {
                            UILabel(text: L10n.totalFee, weight: .semibold)
                            UIView.spacer
                            UILabel(text: self.calculateTotalFee(fees: value))
                        }
                    }
                default: return UIView()
                }
            }
        }

        func formatAmount(fee: PayingFee) -> String {
            "\(fee.lamports.convertToBalance(decimals: fee.token.decimals).toString(maximumFractionDigits: Int(fee.token.decimals + 1))) \(fee.token.symbol)"
        }

        func calculateTotalFee(fees: [PayingFee]) -> String {
            let totalFeesSymbol = fees.first(where: { $0.type == .transactionFee })?.token.symbol
            if let totalFeesSymbol = totalFeesSymbol {
                let totalFees = fees.filter { $0.token.symbol == totalFeesSymbol }
                let decimals = totalFees.first?.token.decimals ?? 0
                let amount =
                    totalFees
                    .reduce(UInt64(0)) { $0 + $1.lamports }
                    .convertToBalance(decimals: decimals)
                    .toString(maximumFractionDigits: Int(decimals)) + " \(totalFeesSymbol)"
                return amount
            }
            return ""
        }

        func row(title: String, descriptions: [String]) -> UIView {
            BEHStack(alignment: .top) {
                UILabel(text: title, textColor: .h8e8e93)
                UIView.spacer
                BEVStack(alignment: .trailing) {
                    for (index, description) in descriptions.enumerated() {
                        if index == 0 {
                            UILabel(text: description)
                        }
                        else {
                            UILabel(text: "+ \(description)")
                        }
                    }
                }

            }.padding(.init(only: .bottom, inset: 12))
        }
    }
}
