import AnalyticsManager
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
    case buy
    case receive(publicKey: PublicKey)
    case send
    case swap
    case cashOut
    case earn
    case solanaAccount(SolanaAccount)
    case claim(EthereumAccount, WormholeClaimUserAction?)
    case actions([WalletActionType])
    // HomeEmpty
    case topUpCoin(Token)
    // Error
    case error(show: Bool)
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
            viewModelWithTokens: tokensViewModel!,
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
        navigation
            .flatMap { [unowned self] in
                navigate(to: $0, homeView: homeView)
            }
            .sink(receiveValue: {})
            .store(in: &subscriptions)

        // return publisher
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }

    // MARK: - Navigation

    private func navigate(to scene: HomeNavigation, homeView: UIViewController) -> AnyPublisher<Void, Never> {
        switch scene {
        case .buy:
            return coordinate(to: BuyCoordinator(navigationController: navigationController, context: .fromHome))
                .map { _ in () }
                .eraseToAnyPublisher()
        case let .receive(publicKey):
            if available(.ethAddressEnabled) {
                let coordinator = SupportedTokensCoordinator(
                    presentation: SmartCoordinatorPushPresentation(navigationController)
                )
                return coordinate(to: coordinator)
                    .eraseToAnyPublisher()
            } else {
                let coordinator = ReceiveCoordinator(
                    network: .solana(tokenSymbol: "SOL", tokenImage: .image(.solanaIcon)),
                    presentation: SmartCoordinatorPushPresentation(navigationController)
                )
                return coordinate(to: coordinator).eraseToAnyPublisher()
            }
        case .send:
            return coordinate(
                to: SendCoordinator(
                    rootViewController: navigationController,
                    preChosenWallet: nil,
                    hideTabBar: true,
                    allowSwitchingMainAmountType: true
                )
            )
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] result in
                switch result {
                case let .sent(model):
                    self?.navigationController.popToRootViewController(animated: true)
                    self?.showSendTransactionStatus(model: model)
                case let .wormhole(trx):
                    self?.navigationController.popToRootViewController(animated: true)
                    self?.showUserAction(userAction: trx)
                case .sentViaLink:
                    self?.navigationController.popToRootViewController(animated: true)
                case .cancelled:
                    break
                }
            })
            .map { _ in () }
            .eraseToAnyPublisher()
        case let .claim(account, userAction):
            if let userAction, userAction.status == .processing {
                return coordinate(to: TransactionDetailCoordinator(
                    viewModel: .init(userAction: userAction),
                    presentingViewController: self.navigationController
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
        case .swap:
            analyticsManager.log(event: .swapViewed(lastScreen: "main_screen"))
            return coordinate(
                to: JupiterSwapCoordinator(
                    navigationController: navigationController,
                    params: JupiterSwapParameters(
                        dismissAfterCompletion: true,
                        openKeyboardOnStart: true,
                        source: .actionPanel
                    )
                )
            )
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
        case .earn:
            return Just(())
                .eraseToAnyPublisher()

        case let .solanaAccount(solanaAccount):
            analyticsManager.log(event: .mainScreenTokenDetailsOpen(tokenTicker: solanaAccount.data.token.symbol))
            
            return coordinate(
                to: AccountDetailsCoordinator(
                    args: .solanaAccount(solanaAccount),
                    presentingViewController: navigationController
                )
            )
            .map { _ in () }
            .eraseToAnyPublisher()
        case .actions:
            return Just(())
                .eraseToAnyPublisher()
        case let .topUpCoin(token):
            // SOL, USDC
            if [Token.nativeSolana, .usdc].contains(token) {
                let coordinator = BuyCoordinator(
                    navigationController: navigationController,
                    context: .fromHome,
                    defaultToken: token
                )
                return coordinate(to: coordinator)
                    .eraseToAnyPublisher()
            }

            // Other
            var token = token
            if token == .renBTC {
                token = Token(.renBTC, customSymbol: "BTC")
            }
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
                    Resolver.resolve(WalletsRepository.self).reload()
                })
            }
            return Just(())
                .eraseToAnyPublisher()
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
}
