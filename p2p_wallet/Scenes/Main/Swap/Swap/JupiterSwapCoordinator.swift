import Combine
import SwiftUI
import KeyAppUI
import SolanaSwift
import Resolver

enum JupiterSwapSource: String {
    case actionPanel, tapMain, tapToken, solend
}

struct JupiterSwapParameters {
    let preChosenWallet: Wallet?
    let dismissAfterCompletion: Bool
    let openKeyboardOnStart: Bool
    let hideTabBar: Bool
    let source: JupiterSwapSource // This param's necessary for the analytic. It doesn't do any logic

    init(dismissAfterCompletion: Bool, openKeyboardOnStart: Bool, source: JupiterSwapSource, preChosenWallet: Wallet? = nil, hideTabBar: Bool = false) {
        self.preChosenWallet = preChosenWallet
        self.dismissAfterCompletion = dismissAfterCompletion
        self.openKeyboardOnStart = openKeyboardOnStart
        self.source = source
        self.hideTabBar = hideTabBar
    }
}

final class JupiterSwapCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private var result = PassthroughSubject<Void, Never>()
    private let params: JupiterSwapParameters
    private var viewModel: SwapViewModel!
    
    private var swapSettingBarButton: UIBarButtonItem!

    init(navigationController: UINavigationController, params: JupiterSwapParameters) {
        self.navigationController = navigationController
        self.params = params
    }

    override func start() -> AnyPublisher<Void, Never> {
        // create shared stateMachine
        let stateMachine = JupiterSwapStateMachine(
            initialState: .zero,
            services: JupiterSwapServices(
                jupiterClient: Resolver.resolve(),
                pricesAPI: Resolver.resolve(),
                solanaAPIClient: Resolver.resolve(),
                relayContextManager: Resolver.resolve()
            )
        )
        
        // input viewModels
        let fromTokenInputViewModel = SwapInputViewModel(
            stateMachine: stateMachine,
            isFromToken: true,
            openKeyboardOnStart: params.openKeyboardOnStart
        )
        
        let toTokenInputViewModel = SwapInputViewModel(
            stateMachine: stateMachine,
            isFromToken: false,
            openKeyboardOnStart: params.openKeyboardOnStart
        )
        
        // swap viewModel
        viewModel = SwapViewModel(
            stateMachine: stateMachine,
            fromTokenInputViewModel: fromTokenInputViewModel,
            toTokenInputViewModel: toTokenInputViewModel,
            source: params.source,
            preChosenWallet: params.preChosenWallet
        )
        
        // view
        let view = SwapView(viewModel: viewModel)
        let controller: UIViewController = view.asViewController(withoutUIKitNavBar: false)
        controller.hidesBottomBarWhenPushed = params.hideTabBar
//        if params.openKeyboardOnStart {
//            controller = KeyboardAvoidingViewController(rootView: view)
//        } else {
//            controller = UIHostingController(rootView: view)
//        }
        navigationController.pushViewController(controller, animated: true)
        style(controller: controller)

        viewModel.submitTransaction
            .sink { [weak self] transaction, statusContext in
                self?.openDetails(pendingTransaction: transaction, statusContext: statusContext)
            }
            .store(in: &subscriptions)

        fromTokenInputViewModel.changeTokenPressed
            .sink { [weak self, unowned fromTokenInputViewModel] in
                guard let self else { return }
                fromTokenInputViewModel.isFirstResponder = false
                self.openChooseToken(fromToken: true)
            }
            .store(in: &subscriptions)
        toTokenInputViewModel.changeTokenPressed
            .sink { [weak self, unowned fromTokenInputViewModel] in
                guard let self else { return }
                fromTokenInputViewModel.isFirstResponder = false
                self.openChooseToken(fromToken: false)
            }
            .store(in: &subscriptions)
        
        return result.prefix(1).eraseToAnyPublisher()
    }
    
    func style(controller: UIViewController) {
//        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController.navigationBar.backgroundColor = Asset.Colors.smoke.color
        controller.title = L10n.swap
        swapSettingBarButton = UIBarButtonItem(image: .receipt, style: .plain, target: self, action: #selector(receiptButtonPressed))
        
        // show rightBarButtonItem only on successful loading
        viewModel.$initializingState
            .map { state -> Bool in
                switch state {
                case .loading, .failed:
                    return false
                case .success:
                    return true
                }
            }
            .removeDuplicates()
            .sink { [weak controller, weak swapSettingBarButton] show in
                if !show {
                    controller?.navigationItem.rightBarButtonItem = nil
                } else if controller?.navigationItem.rightBarButtonItem == nil {
                    controller?.navigationItem.rightBarButtonItem = swapSettingBarButton
                }
            }
            .store(in: &subscriptions)
    }
    
    @objc private func receiptButtonPressed() {
        openSwapSettings()
    }

    private func openChooseToken(fromToken: Bool) {
        coordinate(to: ChooseSwapTokenCoordinator(
            chosenWallet: fromToken ? viewModel.currentState.fromToken : viewModel.currentState.toToken,
            tokens: fromToken ? viewModel.currentState.swapTokens : viewModel.currentState.possibleToTokens,
            navigationController: navigationController,
            title: fromToken ? L10n.theTokenYouPay : L10n.theTokenYouReceive
        ))
        .sink(receiveValue: { [weak viewModel] chosenToken in
            guard let chosenToken else {
                viewModel?.logReturnFromChangeToken(isFrom: fromToken)
                return
            }
            if fromToken {
                viewModel?.changeFromToken.send(chosenToken)
            } else {
                viewModel?.changeToToken.send(chosenToken)
            }
        })
        .store(in: &subscriptions)
    }

    private func openDetails(pendingTransaction: PendingTransaction, statusContext: String?) {
        let viewModel = TransactionDetailViewModel(pendingTransaction: pendingTransaction, statusContext: statusContext)
        var hasError = false
        self.viewModel.logTransactionProgressOpened()
        coordinate(to: TransactionDetailCoordinator(
            viewModel: viewModel,
            presentingViewController: navigationController
        ))
        .sink(receiveCompletion: { [weak self] _ in
            guard let self else { return }
            self.viewModel.logTransactionProgressDone()
            if self.params.dismissAfterCompletion && !hasError {
                self.navigationController.popViewController(animated: true)
                self.result.send(())
            }
        }, receiveValue: { [weak self] status in
            switch status {
            case let .error(_, error):
                hasError = true
                self?.viewModel.logTransaction(error: error)
                if let error, error.isSlippageError {
                    self?.openSwapSettings()
                }
            default:
                hasError = false
            }
        })
        .store(in: &subscriptions)
    }

    private func openSwapSettings() {
        // create coordinator
        let settingsCoordinator = SwapSettingsCoordinator(
            navigationController: navigationController,
            slippage: Double(viewModel.currentState.slippageBps) / 100,
            swapStatePublisher: viewModel.stateMachine.statePublisher
        )
        viewModel.logSettingsClick()

        // coordinate
        coordinate(to: settingsCoordinator)
            .sink(receiveValue: { [weak viewModel] result in
                switch result {
                case let .selectedSlippageBps(slippageBps):
                    Task { [weak viewModel] in
                        await viewModel?.stateMachine.accept(action: .changeSlippageBps(slippageBps))
                    }
                case let .selectedRoute(routeInfo):
                    guard let route = viewModel?.currentState.routes.first(where: {$0.id == routeInfo.id}),
                          route.id != viewModel?.currentState.route?.id
                    else {
                        return
                    }
                    Task { [weak viewModel] in
                        await viewModel?.stateMachine.accept(action: .chooseRoute(route))
                    }
                }
            })
            .store(in: &subscriptions)
    }
}
