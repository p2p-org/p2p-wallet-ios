import Combine
import Send
import SolanaSwift
import SwiftUI

enum SendTransactionDetailsCoordinatorResult {
    case redirectToFeePrompt(availableTokens: [Wallet])
    case cancel
}

final class SendTransactionDetailsCoordinator: Coordinator<SendTransactionDetailsCoordinatorResult> {
    private let parentController: UIViewController
    private let sendInputViewModel: SendInputViewModel

    init(parentController: UIViewController, sendInputViewModel: SendInputViewModel) {
        self.parentController = parentController
        self.sendInputViewModel = sendInputViewModel
    }

    override func start() -> AnyPublisher<SendTransactionDetailsCoordinatorResult, Never> {
        let viewModel = SendTransactionDetailViewModel(stateMachine: sendInputViewModel.stateMachine)
        let view = SendTransactionDetailView(viewModel: viewModel)
        let feeController = BottomSheetController(showHandler: false, rootView: view)
        feeController.modalPresentationStyle = .custom
        parentController.present(feeController, animated: true)

        let result = Publishers.Merge(
            viewModel.cancelSubject.map { SendTransactionDetailsCoordinatorResult.cancel },
            viewModel.feePrompt.map { SendTransactionDetailsCoordinatorResult.redirectToFeePrompt(availableTokens: $0) }
        ).handleEvents(receiveOutput: { _ in
            feeController.dismiss(animated: true)
        })

        return Publishers.Merge(
            result,
            feeController.deallocatedPublisher().map { SendTransactionDetailsCoordinatorResult.cancel }
        ).prefix(1).eraseToAnyPublisher()
    }
}
