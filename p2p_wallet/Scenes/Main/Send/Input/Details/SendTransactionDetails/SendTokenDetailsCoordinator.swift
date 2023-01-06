import Combine
import Send
import SolanaSwift
import SwiftUI

enum SendTransactionDetailsCoordinatorResult {
    case redirectToFeePrompt(availableTokens: [Wallet])
}

final class SendTransactionDetailsCoordinator: Coordinator<SendTransactionDetailsCoordinatorResult> {

    private let parentController: UIViewController
    private var subject = PassthroughSubject<SendTransactionDetailsCoordinatorResult, Never>()

    private let sendInputViewModel: SendInputViewModel

    init(parentController: UIViewController, sendInputViewModel: SendInputViewModel) {
        self.parentController = parentController
        self.sendInputViewModel = sendInputViewModel
    }

    override func start() -> AnyPublisher<SendTransactionDetailsCoordinatorResult, Never> {
        let viewModel = SendTransactionDetailViewModel(stateMachine: sendInputViewModel.stateMachine)

        let view = SendTransactionDetailView(viewModel: viewModel)

        let viewController = UIBottomSheetHostingController(rootView: view, ignoresKeyboard: true)
        viewController.view.layer.cornerRadius = 20
        
        var shouldSendCompletion = true
        viewModel.cancelSubject.sink(receiveValue: { [weak viewController] in
            viewController?.dismiss(animated: true)
        })
        .store(in: &subscriptions)

        viewModel.feePrompt.sink { [weak self, weak viewController] tokens in
            guard let self = self else { return }
            shouldSendCompletion = false
            viewController?.dismiss(animated: true)
            self.subject.send(.redirectToFeePrompt(availableTokens: tokens))
        }
        .store(in: &subscriptions)
        
        viewModel.$cellModels
            .receive(on: RunLoop.main)
            .sink { [weak viewController] _ in
                viewController?.updatePresentationLayout(animated: true)
            }
            .store(in: &subscriptions)
        
        viewController.deallocatedPublisher()
            .filter {shouldSendCompletion}
            .sink { [weak self] in
                self?.subject.send(completion: .finished)
            }
            .store(in: &subscriptions)
        parentController.present(viewController, interactiveDismissalType: .standard)

        return subject.eraseToAnyPublisher()
    }
}
