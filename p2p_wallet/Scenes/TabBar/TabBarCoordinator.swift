import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Sell
import SolanaSwift
import UIKit

final class TabBarCoordinator: Coordinator<Void> {
    // MARK: - Dependencies

    @Injected private var userWalletManager: UserWalletManager
    @Injected private var walletsRepository: SolanaAccountsService
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var sellDataService: any SellDataService

    // MARK: - Properties

    private unowned var window: UIWindow!
    private let tabBarViewModel: TabBarViewModel
    private let tabBarController: TabBarController
    private let closeSubject = PassthroughSubject<Void, Never>()
    private var sendStatusCoordinator: SendTransactionStatusCoordinator?
    private var jupiterSwapTabCoordinator: JupiterSwapCoordinator?

    // MARK: - Initializer

    init(
        window: UIWindow,
        authenticateWhenAppears: Bool,
        appEventHandler _: AppEventHandlerType = Resolver.resolve()
    ) {
        self.window = window
        tabBarViewModel = TabBarViewModel()
        tabBarController = TabBarController(
            viewModel: tabBarViewModel,
            authenticateWhenAppears: authenticateWhenAppears
        )
        super.init()
    }

    // MARK: - Life cycle

    /// Start coordinator
    override func start() -> AnyPublisher<Void, Never> {
        // set up tabs
        let secondTab = setUpSwap()
        let (firstTab, thirdTab) = setupCryptoAndHistory()
        let forthTab = setUpSettings()

        // set viewcontrollers
        tabBarController.setViewControllers(
            [
                firstTab,
                secondTab,
                thirdTab,
                forthTab,
            ],
            animated: false
        )

        // set up tab items
        tabBarController.setupTabs()

        // configure window
        window.rootViewController?.view.hideLoadingIndicatorView()
        window.animate(newRootViewController: tabBarController)

        // re-register for push notification if not yet registered
        if Defaults.didSetEnableNotifications, Defaults.apnsDeviceToken == nil {
            UIApplication.shared.registerForRemoteNotifications()
        }

        bind()

        return closeSubject.prefix(1).eraseToAnyPublisher()
    }

    private func bind() {
        tabBarViewModel.moveToSendViaLinkClaim
            .sink { [weak self] url in
                guard let self else { return }

                UIApplication.dismissCustomPresentedViewController {
                    let claimCoordinator = ReceiveFundsViaLinkCoordinator(
                        presentingViewController: UIApplication.topmostViewController() ?? self.tabBarController,
                        url: url
                    )
                    self.coordinate(to: claimCoordinator)
                        .sink(receiveValue: {})
                        .store(in: &self.subscriptions)
                }
            }
            .store(in: &subscriptions)

        tabBarViewModel.moveToSwap
            .sink { [weak self] url in
                guard let self else { return }
                guard let vc = UIApplication.topmostViewController()?.navigationController ?? self.tabBarController
                    .navigationController else { return }

                let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: true)
                let inputMint = urlComponent?.queryItems?.first { $0.name == "inputMint" }?.value
                let outputMint = urlComponent?.queryItems?.first { $0.name == "outputMint" }?.value
                let from = urlComponent?.queryItems?.first { $0.name == "from" }?.value
                let to = urlComponent?.queryItems?.first { $0.name == "to" }?.value

                self.routeToSwap(
                    nc: vc,
                    source: .tapToken,
                    inputMint: inputMint,
                    outputMint: outputMint,
                    inputSymbol: from,
                    outputSymbol: to
                )
            }
            .store(in: &subscriptions)

        listenToWallet()
    }

    // MARK: - Helpers

    /// Set up Home scene
    private func setUpHome() -> UIViewController {
        // create first active tab Home
        let homeNavigation = UINavigationController()
        let homeCoordinator = HomeCoordinator(navigationController: homeNavigation, tabBarController: tabBarController)

        // coordinate to homeCoordinator
        coordinate(to: homeCoordinator)
            .sink(receiveValue: {})
            .store(in: &subscriptions)

        // scroll to top when home tab clicked twice
        tabBarController.homeTabClickedTwicely
            .sink(receiveValue: { [weak homeCoordinator] in
                homeCoordinator?.scrollToTop()
            })
            .store(in: &subscriptions)

        return homeNavigation
    }

    /// Set up Crypto and History scenes
    private func setupCryptoAndHistory() -> (UIViewController, UIViewController) {
        let cryptoNavigation = UINavigationController()

        routeToCrypto(nc: cryptoNavigation)

        let historyNavigation = UINavigationController()
        historyNavigation.navigationBar.prefersLargeTitles = true

        let historyCoordinator = NewHistoryCoordinator(
            presentation: SmartCoordinatorPushPresentation(historyNavigation)
        )
        coordinate(to: historyCoordinator)
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)

        return (cryptoNavigation, historyNavigation)
    }

    /// Set up Swap scene
    private func setUpSwap() -> UIViewController {
        let nc = UINavigationController()
        routeToSwap(nc: nc, hidesBottomBarWhenPushed: false, source: .tapMain)
        return nc
    }

    /// Set up Settings scene
    private func setUpSettings() -> UIViewController {
        let settingsNavigation = UINavigationController()
        let settingsCoordinator = SettingsCoordinator(navigationController: settingsNavigation)
        coordinate(to: settingsCoordinator)
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)
        return settingsNavigation
    }

    private func listenToWallet() {
        userWalletManager.$wallet
            .sink { [weak self] wallet in
                if wallet == nil {
                    self?.closeSubject.send()
                }
            }
            .store(in: &subscriptions)
    }

    // MARK: - Helpers

    private func navigationControllerForSelectedTab() -> UINavigationController? {
        tabBarController.selectedViewController as? UINavigationController
    }

    private func routeToSendTransactionStatus(model: SendTransaction) {
        sendStatusCoordinator = SendTransactionStatusCoordinator(parentController: tabBarController, transaction: model)

        sendStatusCoordinator?
            .start()
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func showUserAction(userAction: any UserAction) {
        coordinate(to: TransactionDetailCoordinator(
            viewModel: .init(userAction: userAction),
            presentingViewController: tabBarController
        ))
        .sink(receiveValue: { _ in })
        .store(in: &subscriptions)
    }

    private func showSendTransactionStatus(navigationController: UINavigationController, model: SendTransaction) {
        coordinate(to: SendTransactionStatusCoordinator(parentController: navigationController, transaction: model))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func routeToCrypto(
        nc: UINavigationController
    ) {
        let cryptoCoordinator = CryptoCoordinator(navigationController: nc)
        coordinate(to: cryptoCoordinator)
            .sink(receiveValue: { [weak self] _ in
                guard self?.tabBarController.selectedIndex != TabItem.wallet.rawValue else { return }
                self?.tabBarController.changeItem(to: .wallet)
            })
            .store(in: &subscriptions)
    }

    private func routeToSwap(
        nc: UINavigationController,
        hidesBottomBarWhenPushed: Bool = true,
        source: JupiterSwapSource,
        inputMint: String? = nil,
        outputMint: String? = nil,
        inputSymbol: String? = nil,
        outputSymbol: String? = nil
    ) {
        let swapCoordinator = JupiterSwapCoordinator(
            navigationController: nc,
            params: JupiterSwapParameters(
                dismissAfterCompletion: source != .tapMain,
                openKeyboardOnStart: source != .tapMain,
                source: source,
                inputMint: inputMint,
                outputMint: outputMint,
                inputSymbol: inputSymbol,
                outputSymbol: outputSymbol,
                hideTabBar: hidesBottomBarWhenPushed
            )
        )
        if source == .tapMain {
            jupiterSwapTabCoordinator = swapCoordinator
        }
        coordinate(to: swapCoordinator)
            .sink(receiveValue: { [weak self] _ in
                guard self?.tabBarController.selectedIndex != TabItem.wallet.rawValue else { return }
                self?.tabBarController.changeItem(to: .wallet)
            })
            .store(in: &subscriptions)
    }
}
