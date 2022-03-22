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
        var clickHandler: ((PayingFee) -> Void)?

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
                        .sorted { el1, el2 in
                            let id1 = value
                                .firstIndex(where: { $0.type.headerString == el1.value.first?.type.headerString }) ?? 0
                            let id2 = value
                                .firstIndex(where: { $0.type.headerString == el2.value.first?.type.headerString }) ?? 0
                            return id1 < id2
                        }

                    return BEVStack {
                        // Fee categories
                        for el in group {
                            if el.value.contains(where: { fee in fee.isFree }) {
                                // Free fee
                                self.customRow(
                                    title: el.key,
                                    trailing: BEVStack {
                                        for fee in el.value {
                                            self.freeFee(fee: fee)
                                                .onTap { [unowned self] in self.clickHandler?(fee) }
                                        }
                                    }
                                )
                            } else {
                                // Normal fee
                                self.row(title: el.key, descriptions: el.value.map { self.formatAmount(fee: $0) })
                            }
                        }
                        // Separator
                        if !value.isEmpty { UIView.defaultSeparator().padding(.init(only: .bottom, inset: 12)) }
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
                let totalFees = fees.filter { $0.token.symbol == totalFeesSymbol && $0.type != .liquidityProviderFee }
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

        func customRow(title: String, trailing: UIView?) -> UIView {
            BEHStack {
                UILabel(text: title, textColor: .h8e8e93)
                UIView.spacer
                if let trailing = trailing {
                    trailing
                }
            }.padding(.init(only: .bottom, inset: 12))
        }

        func freeFee(fee: PayingFee) -> UIView {
            BEHStack {
                UILabel(text: L10n.free)
                if let payBy = fee.info?.payBy {
                    UILabel(text: "(\(payBy))", textColor: .h34c759)
                        .padding(.init(only: .left, inset: 4))
                }
                if fee.info != nil {
                    UIImageView(width: 16, height: 16, image: .info, tintColor: .h34c759)
                        .padding(.init(only: .left, inset: 4))
                }
            }
        }

        func row(title: String, descriptions: [String]) -> UIView {
            BEHStack(alignment: .top) {
                UILabel(text: title, textColor: .h8e8e93)
                UIView.spacer
                BEVStack(alignment: .trailing) {
                    for (index, description) in descriptions.enumerated() {
                        if index == 0 {
                            UILabel(text: description)
                        } else {
                            UILabel(text: "+ \(description)")
                        }
                    }
                }

            }.padding(.init(only: .bottom, inset: 12))
        }
    }
}
