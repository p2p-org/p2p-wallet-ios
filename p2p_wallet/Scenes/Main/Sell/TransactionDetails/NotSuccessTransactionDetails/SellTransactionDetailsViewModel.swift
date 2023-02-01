//
//  SellTransactionDetailsViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 16.12.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import Sell
import KeyAppUI

final class SellTransactionDetailsViewModel: ObservableObject {

    let openHelp = PassthroughSubject<URL, Never>()

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var sellDataService: any SellDataService
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService

    let topViewModel: SellTransactionDetailsTopView.Model
    let strategy: Strategy
    let transactionId: String
    let title: String
    let infoModel: SellTransactionDetailsInfoModel
    let isProcessing: Bool
    let topButtonTitle: String
    let bottomButtonTitle: String?
    let sendInfo: (String, String)?

    private var receiverAddress: String?

    private let resultSubject = PassthroughSubject<Result, Never>()
    var result: AnyPublisher<Result, Never> { resultSubject.eraseToAnyPublisher() }

    init(
        transaction: SellDataServiceTransaction,
        fiat: Fiat,
        strategy: Strategy,
        date: Date,
        tokenImage: UIImage,
        tokenSymbol: String
    ) {
        self.strategy = strategy
        transactionId = transaction.id

        topViewModel = SellTransactionDetailsTopView.Model(
            date: date,
            tokenImage: tokenImage,
            tokenSymbol: tokenSymbol,
            tokenAmount: transaction.baseCurrencyAmount,
            fiatAmount: transaction.quoteCurrencyAmount,
            currency: fiat
        )
        infoModel = SellTransactionDetailsInfoModel(strategy: strategy)

        let amountPart = topViewModel.tokenAmount.tokenAmountFormattedString(symbol: topViewModel.tokenSymbol)

        switch strategy {
        case .processing:
            title = L10n.processing
            sendInfo = (L10n.willBeSentTo, L10n.yourBankAccountViaMoonpay)
            isProcessing = true
            topButtonTitle = L10n.close
            bottomButtonTitle = nil
            logAnalytics(status: "processing")
        case .fundsWereSent:
            title = L10n.theFundsWereSentToYourBankAccount
            sendInfo = (L10n.sentTo, L10n.yourBankAccountViaMoonpay)
            isProcessing = false
            topButtonTitle = L10n.close
            bottomButtonTitle = L10n.removeFromHistory
            logAnalytics(status: "sent")
        case let .youNeedToSend(receiverAddress):
            self.receiverAddress = receiverAddress
            title = "\(L10n.youNeedToSend) \(amountPart)"
            sendInfo = (L10n.sendTo, receiverAddress.truncatingMiddle(numOfSymbolsRevealed: 6))
            isProcessing = false
            topButtonTitle = "\(L10n.send) \(tokenSymbol)"
            bottomButtonTitle = L10n.delete
            logAnalytics(status: "waiting for deposit")
        case .youVeNotSent:
            title = "\(L10n.youVeNotSent) \(amountPart)"
            sendInfo = nil
            isProcessing = false
            topButtonTitle = L10n.tryAgain
            bottomButtonTitle = L10n.deleteTransaction
            logAnalytics(status: "expired")
        }
    }

    func topButtonClicked() {
        switch strategy {
        case .processing:
            resultSubject.send(.cancel)
        case .fundsWereSent:
            resultSubject.send(.cancel)
        case .youNeedToSend:
            resultSubject.send(.send)
        case .youVeNotSent:
            resultSubject.send(.tryAgain)
        }
    }
    
    func bottomButtonClicked() {
        removeClicked()
    }

    func addressCopied() {
        clipboardManager.copyToClipboard(receiverAddress ?? "")
        notificationsService.showToast(title: "🖤", text: L10n.addressWasCopiedToClipboard, haptic: true)
    }

    func helpTapped() {
        guard let url = Constants.helpURL else { return }
        self.openHelp.send(url)
    }

    private func removeClicked() {
        Task {
            do {
                try await sellDataService.deleteTransaction(id: transactionId)
                await MainActor.run { [unowned self] in
                    notificationsService.showToast(title: "🤗", text: L10n.doneRefreshTheHistoryPageForTheUpdatedStatus)
                }
            } catch {
                await MainActor.run { [unowned self] in
                    notificationsService.showToast(title: "😢", text: L10n.ErrorWithDeleting.tryAgain)
                }
            }
        }
        resultSubject.send(.cancel)
    }

    private func logAnalytics(status: String) {
        analyticsManager.log(event: AmplitudeEvent.historySendClicked(status: status))
    }
}

// MARK: - Strategy

extension SellTransactionDetailsViewModel {
    enum Strategy: Equatable {
        case processing
        case fundsWereSent
        case youNeedToSend(receiverAddress: String)
        case youVeNotSent

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.youNeedToSend(let lAddress), .youNeedToSend(let rAddress)):
                return lAddress == rAddress
            case (.processing, .processing):
                return true
            case (.fundsWereSent, .fundsWereSent):
                return true
            case (.youVeNotSent, .youVeNotSent):
                return true
            default:
                return false
            }
        }

        var isYouNeedToSend: Bool {
            switch self {
            case .youNeedToSend:
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - Result

extension SellTransactionDetailsViewModel {
    enum Result {
        case cancel
        case tryAgain
        case send
    }
}

private enum Constants {
    static let helpURL = URL(string: "https://support.moonpay.com/")
}
