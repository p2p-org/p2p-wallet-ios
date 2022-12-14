import Combine
import Foundation

@MainActor
class SellPendingViewModel: BaseViewModel, ObservableObject {
    let sellDataService = MoonpaySellDataService()
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
