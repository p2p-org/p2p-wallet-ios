//
//  SellTransactionDetailsView.swift
//  p2p_wallet
//
//  Created by Ivan on 15.12.2022.
//

import Combine
import SwiftUI
import KeyAppUI

struct SellTransactionDetailsView: View {
    let model: Model

    private let resultSubject = PassthroughSubject<Result, Never>()
    var result: AnyPublisher<Result, Never> { resultSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 36) {
                SellTransactionDetailsTopView(model: model.topViewModel)
                descriptionBlockView
                    .padding(.horizontal, 24)
            }
            Button(
                action: {
                    resultSubject.send(.cancel)
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
            title: model.title,
            withSeparator: false,
            bottomPadding: 4
        )
    }

    private var descriptionBlockView: some View {
        VStack(spacing: 20) {
            infoBlockView
            if model.strategy != .youVeNotSent {
                textView
            }
        }
    }

    private var textView: some View {
        HStack {
            Text("title")
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text4))
            Spacer()
            Text("description")
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

extension SellTransactionDetailsView {
    struct Model {
        let topViewModel: SellTransactionDetailsTopView.Model
        let strategy: Strategy


        fileprivate var title: String {
            switch strategy {
            case .procesing:
                return L10n.processing
            case .fundsWereSent:
                return L10n.theFundsWereSentToYourBankAccount
            case .youNeedToSend, .youVeNotSent:
                let amountPart = topViewModel.tokenAmount.tokenAmount(symbol: topViewModel.tokenSymbol)
                return "\(strategy != .youVeNotSent ? L10n.youNeedToSend : L10n.youVeNotSent) \(amountPart)"
            }
        }
    }

    enum Strategy: Equatable {
        case procesing
        case fundsWereSent
        case youNeedToSend(receiverAddress: String)
        case youVeNotSent

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.youNeedToSend(let lAddress), .youNeedToSend(let rAddress)):
                return lAddress == rAddress
            case (.procesing, .procesing):
                return true
            case (.fundsWereSent, .fundsWereSent):
                return true
            case (.youVeNotSent, .youVeNotSent):
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - Result

extension SellTransactionDetailsView {
    enum Result {
        case cancel
        case removeFromHistory
        case tryAgain
        case send
    }
}

fileprivate typealias TopViewModel = SellTransactionDetailsTopView.Model
fileprivate typealias Model = SellTransactionDetailsView.Model

//struct SellTransactionDetailsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SellTransactionDetailsView(
//            model: Model(
//                topViewModel: TopViewModel(
//                    date: Date(),
//                    tokenImage: .usdc,
//                    tokenSymbol: "SOL",
//                    tokenAmount: 5,
//                    fiatAmount: 300.05,
//                    currency: .eur
//                ),
//                receiverAddress: "FfRB...BeJEr",
//                transactionFee: L10n.freePaidByKeyApp
//            )
//        )
//    }
//}
