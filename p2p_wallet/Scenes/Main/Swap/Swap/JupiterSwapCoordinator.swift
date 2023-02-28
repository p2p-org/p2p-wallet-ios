import Combine
import SwiftUI
import KeyAppUI
import SolanaSwift

final class JupiterSwapCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private var result = PassthroughSubject<Void, Never>()
    private let preChosenWallet: Wallet?
    private let dismissAfterCompletion: Bool

    init(navigationController: UINavigationController, preChosenWallet: Wallet? = nil, dismissAfterCompletion: Bool) {
        self.navigationController = navigationController
        self.preChosenWallet = preChosenWallet
        self.dismissAfterCompletion = dismissAfterCompletion
    }
    
    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SwapViewModel(preChosenWallet: preChosenWallet)
        let fromViewModel = SwapInputViewModel(stateMachine: viewModel.stateMachine, isFromToken: true)
        let toViewModel = SwapInputViewModel(stateMachine: viewModel.stateMachine, isFromToken: false)
        let view = SwapView(viewModel: viewModel, fromViewModel: fromViewModel, toViewModel: toViewModel)
        let controller = KeyboardAvoidingViewController(rootView: view)
        navigationController.pushViewController(controller, animated: true)
        style(controller: controller)

        viewModel.submitTransaction
            .sink { [weak self] transaction in
                self?.openDetails(pendingTransaction: transaction)
            }
            .store(in: &subscriptions)

        fromViewModel.changeTokenPressed
            .sink { [weak viewModel, weak self, unowned fromViewModel] in
                guard let self, let viewModel else { return }
                fromViewModel.isFirstResponder = false
                self.openChooseToken(viewModel: viewModel, fromToken: true)
            }
            .store(in: &subscriptions)
        toViewModel.changeTokenPressed
            .sink { [weak viewModel, weak self, unowned fromViewModel] in
                guard let self, let viewModel else { return }
                fromViewModel.isFirstResponder = false
                self.openChooseToken(viewModel: viewModel, fromToken: false)
            }
            .store(in: &subscriptions)
        
        return result.prefix(1).eraseToAnyPublisher()
    }
    
    func style(controller: UIViewController) {
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.backgroundColor = Asset.Colors.smoke.color
        controller.title = L10n.swap
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(image: .receipt, style: .plain, target: self, action: #selector(receiptButtonPressed))
    }
    
    @objc private func receiptButtonPressed() {
        
    }
    
    private func openChooseToken(viewModel: SwapViewModel, fromToken: Bool) {
        coordinate(to: ChooseSwapTokenCoordinator(
            chosenWallet: fromToken ? viewModel.currentState.fromToken : viewModel.currentState.toToken,
            tokens: fromToken ? viewModel.currentState.swapTokens : viewModel.currentState.possibleToTokens,
            navigationController: navigationController,
            title: fromToken ? L10n.theTokenYouPay : L10n.theTokenYouReceive
        ))
        .compactMap { $0 }
        .sink {
            if fromToken {
                viewModel.changeFromToken.send($0)
            } else {
                viewModel.changeToToken.send($0)
            }
        }
        .store(in: &subscriptions)
    }

    private func openDetails(pendingTransaction: PendingTransaction) {
        let viewModel = DetailTransactionViewModel(pendingTransaction: pendingTransaction)
        var hasError = false
        coordinate(to: TransactionDetailCoordinator(viewModel: viewModel, presentingViewController: navigationController))
            .sink(receiveCompletion: { [weak self] _ in
                guard let self else { return }
                if self.dismissAfterCompletion && !hasError {
                    self.navigationController.popViewController(animated: true)
                    self.result.send(())
                }
            }, receiveValue: { status in
                switch status {
                case .error:
                    hasError = true
                default:
                    hasError = false
                }
            })
            .store(in: &subscriptions)
    }
}