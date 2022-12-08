import Combine
import Foundation

@MainActor
class SellPendingViewModel: BaseViewModel, ObservableObject {
    typealias SendRequest = Void

    let coordinator = CoordinatorIO()

    // MARK: -

    func send() {
        coordinator.send.send()
    }

    func forget() {
        coordinator.dismiss.send()
    }
}

extension SellPendingViewModel {
    struct CoordinatorIO {
        var send = PassthroughSubject<SendRequest, Never>()
        var dismiss = PassthroughSubject<SendRequest, Never>()
    }
}
