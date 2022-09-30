//
//  SolendTransactionDetails.swift
//  p2p_wallet
//
//  Created by Ivan on 29.09.2022.
//

import Combine
import KeyAppUI
import SwiftSVG
import SwiftUI

struct SolendTransactionDetailsView: View {
    let model: Model

    private let closeSubject = PassthroughSubject<Void, Never>()
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 0) {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
            HStack(alignment: .bottom, spacing: 0) {
                Spacer()
                Text(L10n.transactionDetails)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .title3, weight: .semibold))
                    .padding(.top, 18)
                Spacer()
                Button(
                    action: {
                        closeSubject.send()
                    },
                    label: {
                        Image(uiImage: .closeAction)
                    }
                )
            }
            .padding(.trailing, 16)
            .padding(.leading, 32)
            Color(Asset.Colors.rain.color)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            VStack(spacing: 32) {
                cell(
                    title: model.strategy == .deposit ? L10n.deposit : L10n.withdraw,
                    subtitle: model.formattedAmount
                )
                cell(
                    title: L10n.transferFee,
                    subtitle: model.formattedTransferFee,
                    free: model.transferFee == nil
                )
                cell(
                    title: model.strategy == .withdraw ? L10n.withdrawalFee : L10n.depositFees,
                    subtitle: model.formattedFee,
                    free: model.fee == nil
                )
                cell(
                    title: L10n.total,
                    subtitle: model.formattedTotal
                )
            }
            .padding(.top, 32)
            Button(
                action: {
                    closeSubject.send()
                },
                label: {
                    Text(L10n.cancel)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            ).padding(.top, 48)
        }
        .padding(.top, 6)
        .padding(.bottom, 16)
    }

    private func cell(title: String, subtitle: String, free: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text2))
            Spacer()
            if free {
                HStack(spacing: 6) {
                    Text(L10n.free)
                        .font(uiFont: .font(of: .text2))
                    Image(uiImage: .feeInfo)
                        .frame(width: 16, height: 16)
                }
                .foregroundColor(Color(Asset.Colors.mint.color))
            } else {
                Text(subtitle)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text2))
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Model

extension SolendTransactionDetailsView {
    struct Model {
        let strategy: Strategy
        let amount: Double
        let fiatAmount: Double
        let transferFee: Double?
        let fiatTransferFee: Double?
        let fee: Double?
        let fiatFee: Double?
        let total: Double
        let fiatTotal: Double
        let symbol: String
        let feeSymbol: String

        var formattedAmount: String {
            "\(amount.tokenAmount(symbol: symbol)) (~\(fiatAmount.fiatAmount()))"
        }

        var formattedTotal: String {
            "\(total.tokenAmount(symbol: symbol)) (~\(fiatTotal.fiatAmount()))"
        }

        var formattedTransferFee: String {
            "\(transferFee?.tokenAmount(symbol: feeSymbol) ?? "") (~\(fiatTransferFee?.fiatAmount() ?? ""))"
        }

        var formattedFee: String {
            "\(fee?.tokenAmount(symbol: feeSymbol) ?? "") (~\(fiatFee?.fiatAmount() ?? ""))"
        }
    }

    enum Strategy {
        case deposit
        case withdraw
    }
}

// MARK: - Height

extension SolendTransactionDetailsView {
    var viewHeight: CGFloat { 433 }
}
