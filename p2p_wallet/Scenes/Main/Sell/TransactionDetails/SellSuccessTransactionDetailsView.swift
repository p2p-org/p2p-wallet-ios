//
//  SellSuccessTransactionDetailsView.swift
//  p2p_wallet
//
//  Created by Ivan on 14.12.2022.
//

import Combine
import SwiftUI
import KeyAppUI

struct SellSuccessTransactionDetailsView: View {
    let model: Model

    private let dismissSubject = PassthroughSubject<Void, Never>()
    var dismiss: AnyPublisher<Void, Never> { dismissSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 36) {
                SellTransactionDetailsTopView(model: model.topViewModel)
                VStack(spacing: 20) {
                    infoText
                    infoBlockView
                }
                .padding(.horizontal, 24)
            }
            Button(
                action: {
                    dismissSubject.send()
                },
                label: {
                    Text(L10n.done)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.night.color))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            )
        }
        .sheetHeader(
            title: L10n.transactionSucceeded,
            withSeparator: false,
            bottomPadding: 4
        )
    }

    private var infoText: some View {
        VStack(alignment: .leading, spacing: 32) {
            textView(title: L10n.sentTo, description: model.formattedAddress)
            textView(title: L10n.transactionFee, description: model.transactionFee)
        }
    }

    private func textView(title: String, description: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text4))
            Spacer()
            Text(description)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text4, weight: .semibold))
        }
    }

    private var infoBlockView: some View {
        ZStack {
            Color(.cdf6cd.withAlphaComponent(0.3))
                .cornerRadius(12)
            HStack(spacing: 12) {
                Image(uiImage: .successSellTransaction)
                Text(L10n.theTransactionHasBeenSuccessfullyCompleted)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text4))
            }
        }
        .frame(height: 72)
    }
}

// MARK: - Model

extension SellSuccessTransactionDetailsView {
    struct Model {
        let topViewModel: SellTransactionDetailsTopView.Model
        let receiverAddress: String
        let transactionFee: String
        
        var formattedAddress: String {
            receiverAddress.truncatingMiddle(numOfSymbolsRevealed: 6)
        }
    }
}

// MARK: - View Height

extension SellSuccessTransactionDetailsView {
    var viewHeight: CGFloat {
        632
    }
}

fileprivate typealias TopViewModel = SellTransactionDetailsTopView.Model
fileprivate typealias Model = SellSuccessTransactionDetailsView.Model

struct SellSuccessTransactionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        SellSuccessTransactionDetailsView(
            model: Model(
                topViewModel: TopViewModel(
                    date: Date(),
                    tokenImage: .usdc,
                    tokenSymbol: "SOL",
                    tokenAmount: 5,
                    fiatAmount: 300.05,
                    currency: .eur
                ),
                receiverAddress: "FfRB...BeJEr",
                transactionFee: L10n.freePaidByKeyApp
            )
        )
    }
}
