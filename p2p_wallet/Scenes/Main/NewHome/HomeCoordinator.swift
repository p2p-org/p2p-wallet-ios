import AnalyticsManager
import BankTransfer
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import SwiftUI
import UIKit
import Wormhole

enum HomeNavigation: Equatable {
    // HomeWithTokens
    case receive(publicKey: PublicKey)
    case cashOut
    case solanaAccount(SolanaAccount)
    case claim(EthereumAccount, WormholeClaimUserAction?)
    case bankTransferClaim(StrigaClaimTransaction)
    case bankTransferConfirm(StrigaWithdrawTransaction)
    // HomeEmpty
    case topUpCoin(TokenMetadata)
    case topUp // Top up via bank transfer, bank card or crypto receive
    case withdrawActions // Withdraw actions My bank account / somone else
    case bankTransfer // Only bank transfer
    case withdrawCalculator
    case withdrawInfo(StrigaWithdrawalInfo, WithdrawConfirmationParameters)
    // Error
    case error(show: Bool)

    // Actions
    case addMoney
}

final class HomeCoordinator: Coordinator<Void> {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    private let navigationController: UINavigationController
    private let tabBarController: TabBarController
    private let resultSubject = PassthroughSubject<Void, Never>()

    var tokensViewModel: HomeAccountsViewModel?
    let navigation = PassthroughSubject<HomeNavigation, Never>()
    /// A list of actions required to check if country is selected
    private let regionSelectionReqired = [HomeNavigation.withdrawActions, .addMoney]

    // MARK: - Initializers

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    // MARK: - Public actions

    func scrollToTop() {
        tokensViewModel?.scrollToTop()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        // Home with tokens
        tokensViewModel = HomeAccountsViewModel(navigation: navigation)

        // home with no token
        let emptyViewModel = HomeEmptyViewModel(navigation: navigation)

        // home view
        let viewModel = HomeViewModel()
        let homeView = HomeView(
            viewModel: viewModel,
            accountsViewModel: tokensViewModel!,
            emptyViewModel: emptyViewModel
        ).asViewController() as! UIHostingControllerWithoutNavigation<HomeView>

        // bind
        Publishers.Merge(
            homeView.viewWillAppear.map { true },
            homeView.viewWillDisappear.map { false }
        )
        .assignWeak(to: \.navigationIsHidden, on: homeView)
        .store(in: &subscriptions)

        // set view controller
        navigationController.setViewControllers([homeView], animated: false)
        navigationController.navigationItem.largeTitleDisplayMode = .never

        navigationController.onClose = { [weak self] in
            self?.resultSubject.send(())
        }

        // handle navigation
        navigation.flatMap({ [unowned self] action in
            if regionSelectionReqired.contains(action), Defaults.region == nil {
                return coordinate(to: SelectRegionCoordinator(navigationController: navigationController))
                    .handleEvents(receiveOutput: { [unowned self] _ in
                        navigationController.popViewController(animated: true)
                    })
                    .flatMap { [unowned self] result in
                        switch result {
                        case .selected(_):
                            return navigate(to: action, homeView: homeView)
                        case .cancelled:
                            return Just(()).eraseToAnyPublisher()
                        }
                    }.eraseToAnyPublisher()
            }
            return navigate(to: action, homeView: homeView)
        })
        .sink(receiveValue: {})
        .store(in: &subscriptions)
        // return publisher
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }

    // MARK: - Navigation

    private func navigate(to scene: HomeNavigation, homeView: UIViewController) -> AnyPublisher<Void, Never> {
        switch scene {
        case .receive:
            if available(.ethAddressEnabled) {
                let coordinator = SupportedTokensCoordinator(
                    presentation: SmartCoordinatorPushPresentation(navigationController)
                )
                return coordinate(to: coordinator)
                    .eraseToAnyPublisher()
            } else {
                let coordinator = ReceiveCoordinator(
                    network: .solana(tokenSymbol: Token.nativeSolana.symbol, tokenImage: .image(.solanaIcon)),
                    presentation: SmartCoordinatorPushPresentation(navigationController)
                )
                return coordinate(to: coordinator).eraseToAnyPublisher()
            }

        case let .claim(account, userAction):
            if let userAction, userAction.status == .processing {
                return coordinate(to: TransactionDetailCoordinator(
                    viewModel: .init(userAction: userAction),
                    presentingViewController: navigationController
                ))
                .map { _ in () }
                .eraseToAnyPublisher()
            } else {
                return coordinate(
                    to: WormholeClaimCoordinator(
                        account: account,
                        presentation: SmartCoordinatorPushPresentation(navigationController)
                    )
                )
                .handleEvents(receiveOutput: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case let .claiming(pendingTrx):
                        self.coordinate(
                            to: TransactionDetailCoordinator(
                                viewModel: .init(userAction: pendingTrx),
                                presentingViewController: self.navigationController
                            )
                        )
                        .sink { _ in }
                        .store(in: &self.subscriptions)
                    }
                })
                .map { _ in () }
                .eraseToAnyPublisher()
            }
        case let .bankTransferClaim(transaction):
            return openBankTransferClaimCoordinator(transaction: transaction)
                .eraseToAnyPublisher()

        case let .bankTransferConfirm(transaction):
            return openBankTransferClaimCoordinator(transaction: transaction)
                .eraseToAnyPublisher()

        case .cashOut:
            analyticsManager.log(event: .sellClicked(source: "Main"))
            return coordinate(
                to: SellCoordinator(navigationController: navigationController)
            )
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] result in
                switch result {
                case .completed:
                    self?.tabBarController.changeItem(to: .history)
                case .interupted:
                    (self?.tabBarController.selectedViewController as? UINavigationController)?
                        .popToRootViewController(animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.tabBarController.changeItem(to: .history)
                    }
                case .none:
                    break
                }
            })
            .map { _ in () }
            .eraseToAnyPublisher()

        case let .solanaAccount(solanaAccount):
            analyticsManager.log(event: .mainScreenTokenDetailsOpen(tokenTicker: solanaAccount.token.symbol))

            return coordinate(
                to: AccountDetailsCoordinator(
                    args: .solanaAccount(solanaAccount),
                    presentingViewController: navigationController
                )
            )
            .map { _ in () }
            .eraseToAnyPublisher()
        case .topUp:
            return Just(()).eraseToAnyPublisher()
        case .bankTransfer:
            return coordinate(to: BankTransferCoordinator(viewController: navigationController))
                .eraseToAnyPublisher()
        case .withdrawActions:
            return coordinate(to: WithdrawActionsCoordinator(viewController: navigationController))
                .flatMap { [unowned self] result in
                    switch result {
                    case .action(let action):
                        switch action {
                        case .transfer:
                            return self.navigate(to: .withdrawCalculator, homeView: homeView)
                        case .user, .wallet:
                            return coordinate(to: SendCoordinator(rootViewController: navigationController, preChosenWallet: nil, allowSwitchingMainAmountType: true))
                                .map {_ in }.eraseToAnyPublisher()
                        }
                    case .cancel:
                        return Just(()).eraseToAnyPublisher()
                    }
                }.eraseToAnyPublisher()
        case .withdrawCalculator:
            return coordinate(to: WithdrawCalculatorCoordinator(
                navigationController: navigationController
            ))
            .flatMap { [unowned self] result in
                switch result {
                case let .transaction(transaction):
                    return openPendingTransactionDetails(transaction: transaction)
                        .eraseToAnyPublisher()
                case .canceled:
                    return Just(()).eraseToAnyPublisher()
                }
            }.eraseToAnyPublisher()
        case let .withdrawInfo(model, params):
            return coordinate(to: WithdrawCoordinator(
                navigationController: navigationController,
                strategy: .confirmation(params),
                withdrawalInfo: model
            ))
            .compactMap { result -> (any StrigaConfirmableTransactionType)? in
                switch result {
                case let .paymentInitiated(challengeId):
                    return StrigaClaimTransaction(
                        challengeId: challengeId,
                        token: .usdc,
                        amount: Double(params.amount),
                        feeAmount: .zero,
                        fromAddress: "",
                        receivingAddress: ""
                    )
                case .canceled, .verified:
                    return nil
                }
            }
            .flatMap { [unowned self] transaction in
                openBankTransferClaimCoordinator(transaction: transaction)
            }
            .eraseToAnyPublisher()
        case let .topUpCoin(token):
            // SOL, USDC
            if [TokenMetadata.nativeSolana, .usdc].contains(token) {
                let coordinator = BuyCoordinator(
                    navigationController: navigationController,
                    context: .fromHome,
                    defaultToken: token
                )
                return coordinate(to: coordinator)
                    .eraseToAnyPublisher()
            }

            // Other
            return coordinate(
                to: HomeBuyNotificationCoordinator(
                    tokenFrom: .usdc, tokenTo: token, controller: navigationController
                )
            )
            .flatMap { result -> AnyPublisher<Void, Never> in
                switch result {
                case .showBuy:
                    return self.coordinate(
                        to: BuyCoordinator(
                            navigationController: self.navigationController,
                            context: .fromHome,
                            defaultToken: .usdc
                        )
                    )
                default:
                    return Just(()).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
        case let .error(show):
            if show {
                homeView.view.showConnectionErrorView(refreshAction: { [unowned homeView] in
                    homeView.view.hideConnectionErrorView()
                    Task {
                        try? await Resolver.resolve(SolanaAccountsService.self).fetch()
                    }
                })
            }
            return Just(())
                .eraseToAnyPublisher()

        case .addMoney:
            return coordinate(to: TopupCoordinator(viewController: tabBarController))
                .handleEvents(receiveOutput: { [weak self] result in
                    switch result {
                    case let .action(action):
                        self?.handleAction(action)
                    case .cancel:
                        break
                    }
                })
                .map { _ in () }
                .eraseToAnyPublisher()
        }
    }

    private func handleAction(_ action: TopupActionsViewModel.Action) {
        guard
            let navigationController = tabBarController.selectedViewController as? UINavigationController
        else { return }

        switch action {
        case .transfer:
            coordinate(to: BankTransferCoordinator(viewController: navigationController))
                .sink { _ in }
                .store(in: &subscriptions)
        case .card:
            let buyCoordinator = BuyCoordinator(
                navigationController: navigationController,
                context: .fromHome,
                defaultToken: .nativeSolana,
                defaultPaymentType: .card
            )
            coordinate(to: buyCoordinator)
                .sink(receiveValue: {})
                .store(in: &subscriptions)
        case .crypto:
            if available(.ethAddressEnabled) {
                let coordinator =
                    SupportedTokensCoordinator(presentation: SmartCoordinatorPushPresentation(navigationController))
                coordinate(to: coordinator).sink { _ in }.store(in: &subscriptions)
            } else {
                let coordinator = ReceiveCoordinator(
                    network: .solana(tokenSymbol: "SOL", tokenImage: .image(.solanaIcon)),
                    presentation: SmartCoordinatorPushPresentation(navigationController)
                )
                coordinate(to: coordinator).sink { _ in }.store(in: &subscriptions)
            }
        }
    }

    private func showUserAction(userAction: any UserAction) {
        coordinate(to: TransactionDetailCoordinator(
            viewModel: .init(userAction: userAction),
            presentingViewController: navigationController
        ))
        .sink(receiveValue: { _ in })
        .store(in: &subscriptions)
    }

    private func showSendTransactionStatus(model: SendTransaction) {
        coordinate(to: SendTransactionStatusCoordinator(parentController: navigationController, transaction: model))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func openBankTransferClaimCoordinator(transaction: any StrigaConfirmableTransactionType)
    -> AnyPublisher<Void, Never> {
        coordinate(to: BankTransferClaimCoordinator(
            navigationController: navigationController,
            transaction: transaction
        ))
        .flatMap { [unowned self] result in
            switch result {
            case let .completed(transaction):
                return openPendingTransactionDetails(transaction: transaction)
                    .eraseToAnyPublisher()
            case .canceled:
                return Just(()).eraseToAnyPublisher()
            }
        }.eraseToAnyPublisher()
    }

    private func openPendingTransactionDetails(transaction: PendingTransaction) -> AnyPublisher<Void, Never> {
        // We need this delay to handle pop animation
        Just(()).delay(for: 0.8, scheduler: RunLoop.main)
            .flatMap { [unowned self] in
                coordinate(to: TransactionDetailCoordinator(
                    viewModel: TransactionDetailViewModel(pendingTransaction: transaction),
                    presentingViewController: navigationController
                ))
            }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
