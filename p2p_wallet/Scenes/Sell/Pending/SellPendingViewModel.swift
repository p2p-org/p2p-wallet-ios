import Combine
import Foundation
import Resolver

final class SellPendingViewModel: BaseViewModel, ObservableObject {
    @Injected var sellDataService: any SellDataService
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService

    private let sendSubject = PassthroughSubject<Void, Never>()
    private let dismissSubject = PassthroughSubject<Void, Never>()
    private let backSubject = PassthroughSubject<Void, Never>()
    var send: AnyPublisher<Void, Never> { sendSubject.eraseToAnyPublisher() }
    var dismiss: AnyPublisher<Void, Never> { dismissSubject.eraseToAnyPublisher() }
    var back: AnyPublisher<Void, Never> { backSubject.eraseToAnyPublisher() }

    let tokenAmount: String
    let fiatAmount: String
    let receiverAddress: String

    let model: Model

    init(model: Model) {
        self.model = model
        tokenAmount = model.tokenAmount.tokenAmount(symbol: model.tokenSymbol)
        fiatAmount = "≈ \(model.fiatAmount.fiatAmount(currency: model.currency))"
        receiverAddress = model.receiverAddress.truncatingMiddle(numOfSymbolsRevealed: 6)
    }

    func sendClicked() {
        sendSubject.send()
    }

    func removeClicked() {
        Task {
            try await sellDataService.deleteTransaction(id: model.id)
        }
        dismissSubject.send()
    }

    func addressCopied() {
        clipboardManager.copyToClipboard(model.receiverAddress)
        notificationsService.showToast(title: "🖤", text: L10n.addressWasCopiedToClipboard, haptic: true)
    }

    func backClicked() {
        backSubject.send()
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
        let currency: Fiat
        let receiverAddress: String
    }
}
