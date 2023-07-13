//
//  BuyTransactionDetailsView.swift
//  p2p_wallet
//
//  Created by Ivan on 29.08.2022.
//

import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

struct BuyTransactionDetailsView: View {
    let model: Model

    private let dismissSubject = PassthroughSubject<Void, Never>()
    var dismiss: AnyPublisher<Void, Never> { dismissSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 18) {
            Color(.rain)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.top, 6)
            VStack(spacing: 43) {
                Text(L10n.transactionDetails)
                    .foregroundColor(Color(.night))
                    .font(uiFont: .font(of: .title3, weight: .semibold))
                VStack(spacing: 34) {
                    VStack(spacing: 46) {
                        Image(.transactionDetailsCat)
                        amounts
                    }
                    .padding(.horizontal, 14)
                    Button(
                        action: {
                            dismissSubject.send()
                        },
                        label: {
                            Text(L10n.done)
                                .foregroundColor(Color(.night))
                                .font(uiFont: .font(of: .text2, weight: .bold))
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                                .background(Color(.rain))
                                .cornerRadius(12)
                                .padding(.bottom, 16)
                        }
                    )
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var amounts: some View {
        VStack(spacing: 16) {
            VStack(spacing: 20) {
                amountView(
                    title: "\(model.token.symbol) \(L10n.price)",
                    amount: model.convertedAmount(model.price),
                    amountColor: .mountain
                )
                amountView(
                    title: L10n.purchaseCost(model.token.symbol),
                    amount: model.convertedAmount(model.purchaseCost)
                )
                amountView(
                    title: L10n.processingFee,
                    amount: model.convertedAmount(model.processingFee)
                )
                amountView(
                    title: L10n.networkFee,
                    amount: model.convertedAmount(model.networkFee)
                )
                Color(.rain)
                    .frame(height: 1)
            }
            amountView(
                title: L10n.total,
                amount: model.convertedAmount(model.total),
                titleColor: .night,
                font: .font(of: .text3, weight: .bold)
            )
        }
    }

    private func amountView(
        title: String,
        amount: String,
        titleColor: ColorResource = .mountain,
        amountColor: ColorResource = .night,
        font: UIFont = .font(of: .text3)
    ) -> some View {
        HStack {
            Text(title)
                .foregroundColor(Color(titleColor))
                .font(uiFont: font)
            Spacer()
            Text(amount)
                .foregroundColor(Color(amountColor))
                .font(uiFont: font)
        }
    }
}

// MARK: - Model

extension BuyTransactionDetailsView {
    struct Model {
        let price: Double
        let purchaseCost: Double
        let processingFee: Double
        let networkFee: Double
        let total: Double
        let currency: Fiat
        let token: Token

        fileprivate func convertedAmount(_ amount: Double) -> String {
            amount.fiatAmountFormattedString(maximumFractionDigits: 2, currency: currency)
        }
    }
}

// MARK: - View Height

extension BuyTransactionDetailsView {
    var viewHeight: CGFloat {
        664
    }
}
