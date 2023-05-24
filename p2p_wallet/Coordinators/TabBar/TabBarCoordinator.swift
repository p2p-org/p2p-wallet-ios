import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import Resolver
import Sell
import SolanaSwift

final class TabBarCoordinator: Coordinator<Void> {
    // MARK: - Dependencies

    @Injected private var userWalletManager: UserWalletManager
    @Injected private var walletsRepository: WalletsRepository
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
        bind()
    }

    // MARK: - Life cycle

    /// Start coordinator
    override func start() -> AnyPublisher<Void, Never> {
        // set up tabs
        let firstTab = setUpHome()
        let (secondTab, thirdTab) = setUpSolendSwapOrHistory()
        let forthTab = setUpSettings()

        // set viewcontrollers
        tabBarController.setViewControllers(
            [
                firstTab,
                secondTab,
                UINavigationController(),
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
        if Defaults.didSetEnableNotifications && Defaults.apnsDeviceToken == nil {
            UIApplication.shared.registerForRemoteNotifications()
        }

        bind()

        return closeSubject.prefix(1).eraseToAnyPublisher()
    }

    private func bind() {
        tabBarViewModel.moveToSendViaLinkClaim
            .sink { [weak self] url in
                guard let self = self else { return }
                
                UIApplication.dismissCustomPresentedViewController() {
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
        
        listenToActionsButton()
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

        // navigate to Earn from homeCoordinator
        homeCoordinator.navigation
            .filter { $0 == .earn }
            .sink(receiveValue: { [unowned self] _ in
                tabBarController.changeItem(to: .invest)
            })
            .store(in: &subscriptions)

        homeCoordinator.navigation
            .filter { $0 == .topUp }
            .sink(receiveValue: { [unowned self] _ in
                self.handleAction(.topUp)
            })
            .store(in: &subscriptions)

        // scroll to top when home tab clicked twice
        tabBarController.homeTabClickedTwicely
            .sink(receiveValue: { [weak homeCoordinator] in
                homeCoordinator?.scrollToTop()
            })
            .store(in: &subscriptions)

        // solen tutorial clicked
        tabBarController.solendTutorialClicked
            .sink(receiveValue: { [weak self] in
                self?.navigateToSolendTutorial()
            })
            .store(in: &subscriptions)

        tabBarController.jupiterSwapClicked
            .sink { [weak self] in
                self?.jupiterSwapTabCoordinator?.logOpenFromTab()
            }
            .store(in: &subscriptions)
        return homeNavigation
    }

    /// Set up Solend, history or feedback scene
    private func setUpSolendSwapOrHistory() -> (UIViewController, UIViewController) {
        let solendOrSwapNavigation = UINavigationController()

        if available(.investSolendFeature) {
            let solendCoordinator = SolendCoordinator(navigationController: solendOrSwapNavigation)
            coordinate(to: solendCoordinator)
                .sink(receiveValue: { _ in })
                .store(in: &subscriptions)
        } else {
            routeToSwap(nc: solendOrSwapNavigation, hidesBottomBarWhenPushed: false, source: .tapMain)
        }

        let historyNavigation = UINavigationController()
        historyNavigation.navigationBar.prefersLargeTitles = true
        
        let historyCoordinator = NewHistoryCoordinator(
            presentation: SmartCoordinatorPushPresentation(historyNavigation)
        )
        coordinate(to: historyCoordinator)
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)

        return (solendOrSwapNavigation, historyNavigation)
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

    /// Listen to Actions Button
    private func listenToActionsButton() {
        tabBarController.middleButtonClicked
            .receive(on: RunLoop.main)
            // vibration
            .handleEvents(receiveOutput: { [unowned self] in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                analyticsManager.log(event: .actionButtonClick(isSellEnabled: sellDataService.isAvailable))
            })
            // coordinate to ActionsCoordinator
            .flatMap { [unowned self, unowned tabBarController] in
                coordinate(to: ActionsCoordinator(viewController: tabBarController))
            }
            .sink(receiveValue: { [weak self] result in
                switch result {
                case .cancel:
                    break
                case let .action(type):
                    self?.handleAction(type)
                }
            })
            .store(in: &subscriptions)
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

    /// Navigate to SolendTutorial scene
    private func navigateToSolendTutorial() {
        var view = SolendTutorialView(viewModel: .init())
        view.doneHandler = { [weak self] in
            self?.tabBarController.changeItem(to: .invest)
        }
        let vc = UIHostingControllerWithoutNavigation(rootView: view)
        vc.modalPresentationStyle = .fullScreen
        tabBarController.present(vc, animated: true)
    }

    private func handleTopUpAction(_ action: TopupActionsViewModel.Action) {
        guard
            let navigationController = tabBarController.selectedViewController as? UINavigationController
        else { return }

        switch action {
        case .card:
            let buyCoordinator = BuyCoordinator(
                navigationController: navigationController,
                context: .fromHome
            )
            coordinate(to: buyCoordinator).sink {}.store(in: &subscriptions)
        case .crypto:
            self.handleAction(.receive)
        case .transfer:
            // TODO: temprorary, should be removed
            let coord = StrigaRegistrationFirstStepCoordinator(country: "RU", parent: navigationController)
            coordinate(to: coord).sink { _ in }.store(in: &subscriptions)
        }
    }

    /// Handle actions given by Actions button
    private func handleAction(_ action: ActionsView.Action) {
        guard
            let navigationController = tabBarController.selectedViewController as? UINavigationController
        else { return }

        switch action {
        case .buy:
            let buyCoordinator = BuyCoordinator(
                navigationController: navigationController,
                context: .fromHome
            )
            coordinate(to: buyCoordinator).sink {}.store(in: &subscriptions)
        case .topUp:
            let topUpCoordinator = TopupCoordinator(navigationController: navigationController)
            coordinate(to: topUpCoordinator)
                .sink(receiveValue: { [weak self] result in
                    switch result {
                    case .action(let action):
                        self?.handleTopUpAction(action)
                    case .cancel: break
                    }
                })
                .store(in: &subscriptions)
            
        case .receive:
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
        case .swap:
            routeToSwap(nc: navigationController, source: .actionPanel)
        case .send:
            if walletsRepository.getWallets().count > 0 {
                analyticsManager.log(event: .sendViewed(lastScreen: "main_screen"))
                let sendCoordinator = SendCoordinator(
                    rootViewController: navigationController,
                    preChosenWallet: nil,
                    hideTabBar: true,
                    allowSwitchingMainAmountType: true
                )
                coordinate(to: sendCoordinator)
                    .sink(receiveValue: { [weak self] result in
                        switch result {
                        case let .sent(model):
                            navigationController.popToRootViewController(animated: true)
                            self?.routeToSendTransactionStatus(model: model)

                        case let .wormhole(userAction):
                            navigationController.popToRootViewController(animated: true)
                            self?.showUserAction(userAction: userAction)

                        case .sentViaLink:
                            navigationController.popToRootViewController(animated: true)

                        case .cancelled:
                            break
                        }
                    })
                    .store(in: &subscriptions)
            } else {
                let emptySendCoordinator = SendEmptyCoordinator(navigationController: navigationController)
                coordinate(to: emptySendCoordinator)
                    .sink(receiveValue: {})
                    .store(in: &subscriptions)
            }
        case .cashOut:
            guard available(.sellScenarioEnabled) else { return }
            
            let sellCoordinator = SellCoordinator(navigationController: navigationController)
            coordinate(to: sellCoordinator)
                .sink(receiveValue: { [weak self] result in
                    switch result {
                    case .completed, .interupted:
                        self?.tabBarController.changeItem(to: .history)
                    case .none:
                        break
                    }
                })
                .store(in: &subscriptions)
        }
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

    private func routeToSwap(
        nc: UINavigationController,
        hidesBottomBarWhenPushed: Bool = true,
        source: JupiterSwapSource
    ) {
        let swapCoordinator = JupiterSwapCoordinator(
            navigationController: nc,
            params: JupiterSwapParameters(
                dismissAfterCompletion: source != .tapMain,
                openKeyboardOnStart: source != .tapMain,
                source: source,
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
