import Combine
import SwiftUI
import KeyAppUI
import SolanaSwift

enum JupiterSwapSource: String {
    case actionPanel, tapMain, tapToken, solend
}

struct JupiterSwapParameters {
    let preChosenWallet: Wallet?
    let dismissAfterCompletion: Bool
    let openKeyboardOnStart: Bool
    let source: JupiterSwapSource // This param's necessary for the analytic. It doesn't do any logic

    init(dismissAfterCompletion: Bool, openKeyboardOnStart: Bool, source: JupiterSwapSource, preChosenWallet: Wallet? = nil) {
        self.preChosenWallet = preChosenWallet
        self.dismissAfterCompletion = dismissAfterCompletion
        self.openKeyboardOnStart = openKeyboardOnStart
        self.source = source
    }
}

final class JupiterSwapCoordinator: SmartCoordinator<Void> {
    private let navigationController: UINavigationController
    private let params: JupiterSwapParameters
    private var viewModel: SwapViewModel!
    
    private var swapSettingBarButton: UIBarButtonItem!

    init(navigationController: UINavigationController, params: JupiterSwapParameters) {
        self.navigationController = navigationController
        self.params = params
        super.init(presentation: SmartCoordinatorPushPresentation(navigationController))
    }
    
    init(presentedViewController: UIViewController, params: JupiterSwapParameters) {
        self.navigationController = UINavigationController()
        self.params = params
        super.init(presentation: SmartCoordinatorPresentPresentation(presentedViewController))
    }

    override func build() -> UIViewController {
        viewModel = SwapViewModel(source: params.source, preChosenWallet: params.preChosenWallet)
        let fromViewModel = SwapInputViewModel(stateMachine: viewModel.stateMachine, isFromToken: true, openKeyboardOnStart: params.openKeyboardOnStart)
        let toViewModel = SwapInputViewModel(stateMachine: viewModel.stateMachine, isFromToken: false, openKeyboardOnStart: params.openKeyboardOnStart)
        let view = SwapView(viewModel: viewModel, fromViewModel: fromViewModel, toViewModel: toViewModel)
        let controller: UIViewController = view.asViewController(withoutUIKitNavBar: false)
//        if params.openKeyboardOnStart {
//            controller = KeyboardAvoidingViewController(rootView: view)
//        } else {
//            controller = UIHostingController(rootView: view)
//        }
        style(controller: controller)

        viewModel.submitTransaction
            .sink { [weak self] transaction, statusContext in
                self?.openDetails(pendingTransaction: transaction, statusContext: statusContext)
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
        
        if presentation is SmartCoordinatorPushPresentation {
            return controller
        } else {
            contro
            navigationController.setViewControllers([controller], animated: false)
            return navigationController
        }
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
