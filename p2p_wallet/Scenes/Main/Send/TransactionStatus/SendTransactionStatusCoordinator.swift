import Combine
import SwiftUI

final class SendTransactionStatusCoordinator: Coordinator<Void> {
    private var transition: PanelTransition?
    private var viewController: UIViewController?

    private let parentController: UIViewController
    private var subject = PassthroughSubject<Void, Never>()
    private let transaction: SendTransaction

    init(parentController: UIViewController, transaction: SendTransaction) {
        self.parentController = parentController
        self.transaction = transaction
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SendTransactionStatusViewModel(transaction: transaction)
        let view = SendTransactionStatusView(viewModel: viewModel)

        viewModel.close
            .sink { [weak self] in self?.finish() }
            .store(in: &subscriptions)

        transition = PanelTransition()
        transition?.containerHeight = 624.adaptiveHeight
        let viewController = UIHostingController(rootView: view)
        viewController.view.layer.cornerRadius = 20
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom

        transition?.dimmClicked
            .sink { [weak self] in self?.finish() }
            .store(in: &subscriptions)
        parentController.present(viewController, animated: true)
        self.viewController = viewController

        return subject.prefix(1).eraseToAnyPublisher()
    }

    private func finish() {
        viewController?.dismiss(animated: true)
        subject.send(completion: .finished)
    }
}
