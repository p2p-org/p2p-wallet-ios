import Combine
import SwiftUI

struct SendTransactionStatusDetailsParameters {
    let title: String
    let description: String
    let fee: String?
}

enum SendTransactionStatusDetailsCoordinatorResult {
    case close
}

final class SendTransactionStatusDetailsCoordinator: Coordinator<SendTransactionStatusDetailsCoordinatorResult> {
    private let navigationController: UINavigationController
    private var subject = PassthroughSubject<SendTransactionStatusDetailsCoordinatorResult, Never>()
    private let params: SendTransactionStatusDetailsParameters

    init(navigationController: UINavigationController, params: SendTransactionStatusDetailsParameters) {
        self.navigationController = navigationController
        self.params = params
    }

    override func start() -> AnyPublisher<SendTransactionStatusDetailsCoordinatorResult, Never> {
        let viewModel = SendTransactionStatusDetailsViewModel(params: params)
        let view = SendTransactionStatusDetailsView(viewModel: viewModel)

        viewModel.close
            .sink { [weak self] in self?.finish() }
            .store(in: &subscriptions)

        let viewController = UIHostingController(rootView: view)
        viewController.onClose = { [weak self] in
            self?.subject.send(completion: .finished)
        }
        navigationController.pushViewController(viewController, animated: true)
        return subject.prefix(1).eraseToAnyPublisher()
    }

    private func finish() {
        navigationController.dismiss(animated: true)
        subject.send(.close)
        subject.send(completion: .finished)
    }
}
