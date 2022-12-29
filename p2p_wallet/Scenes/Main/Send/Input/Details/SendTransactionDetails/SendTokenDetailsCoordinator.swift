import Combine
import Send
import SolanaSwift
import SwiftUI

enum SendTransactionDetailsCoordinatorResult {
    case redirectToFeePrompt(availableTokens: [Wallet])
}

final class SendTransactionDetailsCoordinator: Coordinator<SendTransactionDetailsCoordinatorResult> {
    private var transition: PanelTransition?
    private var viewController: UIViewController?

    private let parentController: UIViewController
    private var subject = PassthroughSubject<SendTransactionDetailsCoordinatorResult, Never>()

    private let sendInputViewModel: SendInputViewModel

    init(parentController: UIViewController, sendInputViewModel: SendInputViewModel) {
        self.parentController = parentController
        self.sendInputViewModel = sendInputViewModel
    }

    override func start() -> AnyPublisher<SendTransactionDetailsCoordinatorResult, Never> {
        let viewModel = SendTransactionDetailViewModel(stateMachine: sendInputViewModel.stateMachine)
        viewModel.cancelSubject.sink(receiveValue: { [weak self] in
            self?.viewController?.dismiss(animated: true)
            self?.subject.send(completion: .finished)
        })
        .store(in: &subscriptions)

        viewModel.feePrompt.sink { [weak self] tokens in
            guard let self = self else { return }
            self.viewController?.dismiss(animated: true)
            self.subject.send(.redirectToFeePrompt(availableTokens: tokens))
        }
        .store(in: &subscriptions)

        let view = SendTransactionDetailView(viewModel: viewModel)

        transition = PanelTransition()
        transition?.containerHeight = view.viewHeight
        let viewController = UIHostingController(rootView: view, ignoresKeyboard: true)
        viewController.view.layer.cornerRadius = 20
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom

        transition?.dimmClicked
            .sink { [weak self] in
                self?.viewController?.dismiss(animated: true)
                self?.subject.send(completion: .finished)
            }
            .store(in: &subscriptions)
        parentController.present(viewController, animated: true)
        self.viewController = viewController

        return subject.eraseToAnyPublisher()
    }
}
