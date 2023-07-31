import AnalyticsManager
import Combine
import Foundation
import Resolver
import Sell
import UIKit

@MainActor
final class SellPendingViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    @Injected var sellDataService: any SellDataService
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService

    // MARK: - Subjects

    private let sendSubject = PassthroughSubject<Void, Never>()
    private let transactionRemovedSubject = PassthroughSubject<Void, Never>()

    @Published var isRemoving: Bool = false

    // MARK: - Publishers

    var send: AnyPublisher<Void, Never> { sendSubject.eraseToAnyPublisher() }
    var transactionRemoved: AnyPublisher<Void, Never> { transactionRemovedSubject.eraseToAnyPublisher() }

    let tokenAmount: String
    let fiatAmount: String
    let receiverAddress: String

    let model: Model

    init(model: Model) {
        self.model = model
        tokenAmount = model.tokenAmount.tokenAmountFormattedString(symbol: model.tokenSymbol)
        fiatAmount = "≈ \(model.fiatAmount.formattedFiat(currency: Fiat(rawValue: model.currency.rawValue) ?? .usd))"
        receiverAddress = model.receiverAddress.truncatingMiddle(numOfSymbolsRevealed: 6)
    }

    func sendClicked() {
        sendSubject.send()
    }

    func removeClicked() {
        isRemoving = true
        Task {
            do {
                try await sellDataService.deleteTransaction(id: model.id)
                try? await sellDataService.updateIncompletedTransactions()
                await MainActor.run { [unowned self] in
                    notificationsService.showToast(title: "🤗", text: L10n.doneRefreshTheHistoryPageForTheUpdatedStatus)
                    isRemoving = false
                    transactionRemovedSubject.send()
                }
            } catch {
                await MainActor.run { [unowned self] in
                    notificationsService.showToast(title: "😢", text: L10n.ErrorWithDeleting.tryAgain)
                    isRemoving = false
                }
            }
        }
    }

    func addressCopied() {
        clipboardManager.copyToClipboard(model.receiverAddress)
        notificationsService.showToast(title: "🖤", text: L10n.addressWasCopiedToClipboard, haptic: true)
    }

    func viewDidAppear() {
        analyticsManager.log(event: .sellFinishSend)
    }
}

// MARK: - Model

extension SellPendingViewModel {
    struct Model {
        let id: String
        let tokenImage: UIImage
        let tokenSymbol: String
        let tokenAmount: Double
        let fiatAmount: Double
        let currency: any ProviderFiat
        let receiverAddress: String
        let navigatedFromMoonpay: Bool
    }
}
