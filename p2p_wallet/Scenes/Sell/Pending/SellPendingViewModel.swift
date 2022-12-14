import Combine
import Foundation
import Resolver

@MainActor
class SellPendingViewModel: BaseViewModel, ObservableObject {
    @Injected var sellDataService: any SellDataService
    typealias SendRequest = Void

    let coordinator = CoordinatorIO()

    let id: String
    init(id: String) {
        self.id = id
    }

    // MARK: -

    func send() {
        coordinator.send.send()
    }

    func forget() {
        Task {
            try await sellDataService.deleteTransaction(id: id)
        }
        coordinator.dismiss.send()
    }
}

extension SellPendingViewModel {
    struct CoordinatorIO {
        var send = PassthroughSubject<SendRequest, Never>()
        var dismiss = PassthroughSubject<SendRequest, Never>()
    }
}
