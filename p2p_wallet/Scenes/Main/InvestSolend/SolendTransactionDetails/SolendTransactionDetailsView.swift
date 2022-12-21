//
//  SolendTransactionDetails.swift
//  p2p_wallet
//
//  Created by Ivan on 29.09.2022.
//

import Combine
import KeyAppUI
import Solend
import SwiftUI

struct SolendTransactionDetailsView: View {
    @ObservedObject var viewModel: SolendTransactionDetailsViewModel

    private let closeSubject = PassthroughSubject<Void, Never>()
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }

    @State private var coveredByP2PAlert = false

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
                if let model = viewModel.model {
                    cell(
                        title: viewModel.strategy == .deposit ? L10n.deposit : L10n.withdraw,
                        state: .model(model.formattedAmount)
                    )
                    cell(
                        title: L10n.transferFee,
                        state: .model(model.formattedTransferFee, free: model.transferFee == 0)
                    ).onTapGesture {
                        if model.transferFee == 0 {
                            coveredByP2PAlert = true
                        }
                    }.alert(isPresented: $coveredByP2PAlert) {
                        Alert(
                            title: Text(L10n.enjoyFreeTransactions),
                            message: Text(L10n.onTheSolanaNetworkTheFirst100TransactionsInADayArePaidByKeyApp),
                            dismissButton: .cancel(Text(L10n.awesome))
                        )
                    }
                    cell(
                        title: viewModel.strategy == .withdraw ? L10n.withdrawalFee : L10n.depositFees,
                        state: .model(model.formattedFee, free: model.fee == 0)
                    )
                    cell(
                        title: L10n.total,
                        state: .model(model.formattedTotal)
                    )
                } else {
                    cell(
                        title: viewModel.strategy == .deposit ? L10n.deposit : L10n.withdraw,
                        state: .pending
                    )
                    cell(
                        title: L10n.transferFee,
                        state: .pending
                    )
                    cell(
                        title: viewModel.strategy == .withdraw ? L10n.withdrawalFee : L10n.depositFees,
                        state: .pending
                    )
                    cell(
                        title: L10n.total,
                        state: .pending
                    )
                }
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
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 20, corners: [.topLeft, .topRight])
    }

    private func cell(title: String, state: CellState) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text2))
            Spacer()
            switch state {
            case .pending:
                HStack(spacing: 4) {
                    Text(L10n.loading)
                        .foregroundColor(Color(.sea))
                        .font(uiFont: .font(of: .text2))
                    Spinner()
                        .frame(width: 16, height: 16)
                }
            case let .model(text, free):
                trailingCellContent(text: text, free: free)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func trailingCellContent(text: String, free: Bool) -> some View {
        if free {
            HStack(spacing: 6) {
                Text(L10n.free)
                    .font(uiFont: .font(of: .text2))
                Image(uiImage: .feeInfo)
                    .frame(width: 16, height: 16)
            }
            .foregroundColor(Color(Asset.Colors.mint.color))
        } else {
            Text(text)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text2))
        }
    }
}

// MARK: - Model

extension SolendTransactionDetailsView {
    struct Model: Equatable {
        let amount: Double
        let fiatAmount: Double
        let transferFee: Double?
        let fiatTransferFee: Double?
        let fee: Double?
        let fiatFee: Double?
        let total: Double?
        let fiatTotal: Double
        let symbol: String
        let feeSymbol: String

        var formattedAmount: String {
            "\(amount.tokenAmount(symbol: symbol)) (~\(fiatAmount.fiatAmount()))"
        }

        var formattedTotal: String {
            if let total = total {
                return "\(total.tokenAmount(symbol: symbol)) (~\(fiatTotal.fiatAmount()))"
            } else {
                return "~\(fiatTotal.fiatAmount())"
            }
        }

        var formattedTransferFee: String {
            "\(transferFee?.tokenAmount(symbol: feeSymbol) ?? "") (~\(fiatTransferFee?.fiatAmount() ?? ""))"
        }

        var formattedFee: String {
            "\(fee?.tokenAmount(symbol: feeSymbol) ?? "") (~\(fiatFee?.fiatAmount() ?? ""))"
        }
    }
}

// MARK: - Cell State

extension SolendTransactionDetailsView {
    private enum CellState {
        case pending
        case model(String, free: Bool = false)
    }
}

// MARK: - View Height

extension SolendTransactionDetailsView {
    var viewHeight: CGFloat { 433 }
}

// MARK: - Preview

struct SolendTransactionDetailsView_Previews: PreviewProvider {
    static var view: some View {
        ZStack {
            Color(.gray)
            VStack {
                Spacer()
                SolendTransactionDetailsView(
                    viewModel: .init(
                        strategy: .deposit,
                        model: .init(
                            amount: 521,
                            fiatAmount: 322,
                            transferFee: 0,
                            fiatTransferFee: 0,
                            fee: 4,
                            fiatFee: 5,
                            total: 6,
                            fiatTotal: 32,
                            symbol: "SOL",
                            feeSymbol: "USDT"
                        )
                    )
                )
            }
        }
    }

    static var previews: some View {
        view
            .previewDevice(.init(rawValue: "iPhone 12"))
            .previewDisplayName("iPhone 12")

        view
            .previewDevice(.init(rawValue: "iPhone 8"))
            .previewDisplayName("iPhone 8")
    }
}
