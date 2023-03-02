import Combine
import SwiftUI
import KeyAppUI
import SolanaSwift

struct JupiterSwapParameters {
    let preChosenWallet: Wallet?
    let dismissAfterCompletion: Bool
    let openKeyboardOnStart: Bool

    init(dismissAfterCompletion: Bool, openKeyboardOnStart: Bool, preChosenWallet: Wallet? = nil) {
        self.preChosenWallet = preChosenWallet
        self.dismissAfterCompletion = dismissAfterCompletion
        self.openKeyboardOnStart = openKeyboardOnStart
    }
}

final class JupiterSwapCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private var result = PassthroughSubject<Void, Never>()
    private let params: JupiterSwapParameters
    private var viewModel: SwapViewModel!

    init(navigationController: UINavigationController, params: JupiterSwapParameters) {
        self.navigationController = navigationController
        self.params = params
    }

    override func start() -> AnyPublisher<Void, Never> {
        viewModel = SwapViewModel(preChosenWallet: params.preChosenWallet)
        let fromViewModel = SwapInputViewModel(stateMachine: viewModel.stateMachine, isFromToken: true, openKeyboardOnStart: params.openKeyboardOnStart)
        let toViewModel = SwapInputViewModel(stateMachine: viewModel.stateMachine, isFromToken: false, openKeyboardOnStart: params.openKeyboardOnStart)
        let view = SwapView(viewModel: viewModel, fromViewModel: fromViewModel, toViewModel: toViewModel)
        let controller: UIViewController = view.asViewController(withoutUIKitNavBar: false)
//        if params.openKeyboardOnStart {
//            controller = KeyboardAvoidingViewController(rootView: view)
//        } else {
//            controller = UIHostingController(rootView: view)
//        }
        navigationController.pushViewController(controller, animated: true)
        style(controller: controller)

        viewModel.submitTransaction
            .sink { [weak self] transaction in
                self?.openDetails(pendingTransaction: transaction)
            }
            .store(in: &subscriptions)

        fromViewModel.changeTokenPressed
            .sink { [weak self, unowned fromViewModel] in
                guard let self else { return }
                fromViewModel.isFirstResponder = false
                self.openChooseToken(fromToken: true)
            }
            .store(in: &subscriptions)
        toViewModel.changeTokenPressed
            .sink { [weak self, unowned fromViewModel] in
                guard let self else { return }
                fromViewModel.isFirstResponder = false
                self.openChooseToken(fromToken: false)
            }
            .store(in: &subscriptions)
        
        return result.prefix(1).eraseToAnyPublisher()
    }
    
    func style(controller: UIViewController) {
//        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController.navigationBar.backgroundColor = Asset.Colors.smoke.color
        controller.title = L10n.swap
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(image: .receipt, style: .plain, target: self, action: #selector(receiptButtonPressed))
    }
    
    @objc private func receiptButtonPressed() {
        guard let route = viewModel.currentState.route else {
            return
        }
        let settingsCoordinator = SwapSettingsCoordinator(
            navigationController: navigationController,
            slippage: Double(viewModel.currentState.slippage) / 100,
            routes: [],
            currentRoute: route,
            swapTokens: viewModel.currentState.swapTokens
        )
        coordinate(to: settingsCoordinator)
            .sink(receiveValue: { [weak viewModel] result in
                switch result {
                case let .selectedSlippage(slippage):
                    Task { [weak viewModel] in
                        await viewModel?.stateMachine.accept(action: .changeSlippage(slippage))
                    }
                case let .selectedRoute(route):
                    fatalError()
                }
            })
            .store(in: &subscriptions)
    }
    
    private func openChooseToken(fromToken: Bool) {
        coordinate(to: ChooseSwapTokenCoordinator(
            chosenWallet: fromToken ? viewModel.currentState.fromToken : viewModel.currentState.toToken,
            tokens: fromToken ? viewModel.currentState.swapTokens : viewModel.currentState.possibleToTokens,
            navigationController: navigationController,
            title: fromToken ? L10n.theTokenYouPay : L10n.theTokenYouReceive
        ))
        .compactMap { $0 }
        .sink { [weak viewModel] in
            if fromToken {
                viewModel?.changeFromToken.send($0)
            } else {
                viewModel?.changeToToken.send($0)
            }
        }
        .store(in: &subscriptions)
    }

    private func openDetails(pendingTransaction: PendingTransaction) {
        let viewModel = TransactionDetailViewModel(pendingTransaction: pendingTransaction)
        var hasError = false
        coordinate(to: TransactionDetailCoordinator(viewModel: viewModel, presentingViewController: navigationController))
            .sink(receiveCompletion: { [weak self] _ in
                guard let self else { return }
                if self.params.dismissAfterCompletion && !hasError {
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
