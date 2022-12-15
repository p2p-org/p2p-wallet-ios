import Combine
import Foundation
import Resolver

@MainActor
class SellPendingViewModel: BaseViewModel, ObservableObject {
    @Injected var sellDataService: any SellDataService
    typealias SendRequest = Void

    let coordinator = CoordinatorIO()

    let transaction: SellDataServiceTransaction
    let fiat: Fiat
    init(transaction: SellDataServiceTransaction, fiat: Fiat) {
        self.transaction = transaction
        self.fiat = fiat
    }

    // MARK: -

    func send() {
        coordinator.send.send()
    }

    func forget() {
        Task {
//            try await sellDataService.deleteTransaction(id: id)
        }
        coordinator.dismiss.send()
    }
}

extension SellPendingViewModel {
    struct CoordinatorIO {
        var send = PassthroughSubject<SendRequest, Never>()
        var dismiss = PassthroughSubject<Void, Never>()
    }
}
