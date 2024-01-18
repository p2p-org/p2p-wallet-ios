import Combine
import KeyAppKitCore
import Resolver
import SolanaSwift
import SwiftUI
import UIKit

enum JupiterSwapSource: String {
    case actionPanel = "Action_Panel", tapMain = "Tap_Main", tapToken = "Tap_Token", solend = "Solend",
         deeplink = "Deeplink"
}

struct JupiterSwapParameters {
    let preChosenWallet: SolanaAccount?
    let destinationWallet: SolanaAccount?

    let inputMint: String?
    let outputMint: String?

    let dismissAfterCompletion: Bool
    let openKeyboardOnStart: Bool
    let hideTabBar: Bool
    let source: JupiterSwapSource // This param's necessary for the analytic. It doesn't do any logic

    init(
        dismissAfterCompletion: Bool,
        openKeyboardOnStart: Bool,
        source: JupiterSwapSource,
        preChosenWallet: SolanaAccount? = nil,
        destinationWallet: SolanaAccount? = nil,
        inputMint: String? = nil,
        outputMint: String? = nil,
        hideTabBar: Bool = false
    ) {
        self.preChosenWallet = preChosenWallet
        self.destinationWallet = destinationWallet

        self.inputMint = inputMint
        self.outputMint = outputMint

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
    private var shareBarButton: UIBarButtonItem!

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
            preChosenWallet: params.preChosenWallet,
            destinationWallet: params.destinationWallet,
            inputMint: params.inputMint,
            outputMint: params.outputMint
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
                UIApplication.shared.endEditing()
                self.openChooseToken(fromToken: true)
            }
            .store(in: &subscriptions)
        toTokenInputViewModel.changeTokenPressed
            .sink { [weak self, unowned fromTokenInputViewModel] in
                guard let self else { return }
                fromTokenInputViewModel.isFirstResponder = false
                UIApplication.shared.endEditing()
                self.openChooseToken(fromToken: false)
            }
            .store(in: &subscriptions)

        return result.eraseToAnyPublisher()
    }

    func style(controller: UIViewController) {
        controller.title = L10n.swap
        controller.navigationItem.largeTitleDisplayMode = .never

        swapSettingBarButton = UIBarButtonItem(
            image: .init(resource: .receipt),
            style: .plain,
            target: self,
            action: #selector(receiptButtonPressed)
        )

        shareBarButton = UIBarButtonItem(
            image: UIImage(named: "share-1"),
            style: .plain,
            target: self,
            action: #selector(shareButtonPressed)
        )

        // show rightBarButtonItem only on successful loading
        viewModel.$viewState
            .map { state -> Bool in
                switch state {
                case .loading, .failed:
                    return false
                case .success:
                    return true
                }
            }
            .removeDuplicates()
            .sink { [weak controller, weak swapSettingBarButton, weak shareBarButton] show in
                guard let swapSettingBarButton, let shareBarButton else { return }

                if !show {
                    controller?.navigationItem.rightBarButtonItems = [shareBarButton]
                } else {
                    controller?.navigationItem.rightBarButtonItems = [swapSettingBarButton, shareBarButton]
                }
            }
            .store(in: &subscriptions)
    }

    func logOpenFromTab() {
        viewModel.logStartFromMain()
    }

    @objc private func receiptButtonPressed() {
        UIApplication.shared.endEditing()
        openSwapSettings()
    }

    @objc private func shareButtonPressed() {
        UIApplication.shared.endEditing()
        
        let from = viewModel.currentState.fromToken.mintAddress
        let to = viewModel.currentState.toToken.mintAddress
        
        let items = ["https://s.key.app/swap?from=\(from)&to=\(to)"]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
         
        navigationController.present(activityVC, animated: true)
    }

    private func openChooseToken(fromToken: Bool) {
        viewModel.continueUpdateOnDisappear = true
        coordinate(to: ChooseSwapTokenCoordinator(
            chosenWallet: fromToken ? viewModel.currentState.fromToken : viewModel.currentState.toToken,
            tokens: fromToken ? viewModel.currentState.swapTokens : viewModel.currentState.possibleToTokens,
            navigationController: navigationController,
            fromToken: fromToken,
            title: fromToken ? L10n.tokenYouPay : L10n.tokenYouReceive
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
            guard !hasError else { return }
            self.result.send(())
            if self.params.dismissAfterCompletion {
                self.navigationController.popViewController(animated: true)
                self.result.send(completion: .finished)
            } else {
                self.viewModel.reset()
            }
        }, receiveValue: { [weak self] status in
            switch status {
            case let .error(_, error):
                hasError = true
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
        viewModel.continueUpdateOnDisappear = true
        // create coordinator
        let settingsCoordinator = SwapSettingsCoordinator(
            navigationController: navigationController,
            stateMachine: viewModel.stateMachine
        )
        viewModel.logSettingsClick()
        viewModel.fromTokenInputViewModel.isFirstResponder = false

        // coordinate
        coordinate(to: settingsCoordinator)
            .prefix(1)
            .sink(receiveValue: { [weak viewModel] result in
                viewModel?.fromTokenInputViewModel.isFirstResponder = true
                switch result {
                case let .selectedSlippageBps(slippageBps):
                    Task { [weak viewModel] in
                        await viewModel?.stateMachine.accept(
                            action: .changeSlippageBps(slippageBps)
                        )
                    }
                case let .selectedRoute(routeInfo):
                    guard
                        let route = (viewModel?.currentState.routes.first { $0.id == routeInfo.id }),
                        route.id != viewModel?.currentState.route?.id
                    else { return }
                    Task { [weak viewModel] in
                        await viewModel?.stateMachine.accept(
                            action: .chooseRoute(route)
                        )
                    }
                }
            })
            .store(in: &subscriptions)
    }
}
