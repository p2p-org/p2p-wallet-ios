//
//  TabBarCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 16.11.2022.
//

import Combine
import Foundation
import SolanaSwift
import Resolver
import AnalyticsManager
import Sell

final class TabBarCoordinator: Coordinator<Void> {
    
    // MARK: - Dependencies
    @Injected private var userWalletManager: UserWalletManager
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var sellDataService: any SellDataService

    // MARK: - Properties
    private unowned var window: UIWindow!
    private let tabBarController: TabBarController
    private let closeSubject = PassthroughSubject<Void, Never>()
    
    private var emptySendCoordinator: SendEmptyCoordinator?
    private var sendCoordinator: SendCoordinator?
    private var sendStatusCoordinator: SendTransactionStatusCoordinator?
    private var sellCoordinator: SellCoordinator?

    // MARK: - Initializer

    init(
        window: UIWindow,
        authenticateWhenAppears: Bool,
        appEventHandler: AppEventHandlerType = Resolver.resolve()
    ) {
        self.window = window
        tabBarController = TabBarController(
            viewModel: TabBarViewModel(),
            authenticateWhenAppears: authenticateWhenAppears
        )
        super.init()
        listenToActionsButton()
        listenToWallet()
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

        return closeSubject.prefix(1).eraseToAnyPublisher()
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
            .filter {$0 == .earn}
            .sink(receiveValue: { [unowned self] _ in
                tabBarController.changeItem(to: .invest)
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
            let swapCoordinator = SwapCoordinator(navigationController: solendOrSwapNavigation, initialWallet: nil, hidesBottomBarWhenPushed: false)
            coordinate(to: swapCoordinator)
                .sink(receiveValue: { _ in })
                .store(in: &subscriptions)
        }
        
        let historyNavigation = UINavigationController()
        let historyCoordinator = HistoryCoordinator(presentation: SmartCoordinatorPushPresentation(historyNavigation))
        coordinate(to: historyCoordinator)
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)

        return (solendOrSwapNavigation, historyNavigation)
    }
    
    /// Set up Settings scene
    private func setUpSettings() -> UIViewController {
        let settingsNavigation: UINavigationController
        if available(.settingsFeature) {
            settingsNavigation = UINavigationController()
            let settingsCoordinator = SettingsCoordinator(navigationController: settingsNavigation)
            coordinate(to: settingsCoordinator)
                .sink(receiveValue: { _ in })
                .store(in: &subscriptions)
        } else {
            settingsNavigation = UINavigationController(
                rootViewController: Settings.ViewController(viewModel: Settings.ViewModel())
            )
        }
        return settingsNavigation
    }
    
    /// Listen to Actions Button
    private func listenToActionsButton() {
        tabBarController.middleButtonClicked
            .receive(on: RunLoop.main)
            // vibration
            .handleEvents(receiveOutput: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            })
            // coordinate to ActionsCoordinator
            .flatMap { [unowned self] in
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
            coordinate(to: buyCoordinator)
                .sink(receiveValue: {})
                .store(in: &subscriptions)
        case .receive:
            break
        case .swap:
            let swapCoordinator = SwapCoordinator(navigationController: navigationController, initialWallet: nil)
            coordinate(to: swapCoordinator)
                .sink(receiveValue: { _ in })
                .store(in: &subscriptions)
        case .send:
            let fiatAmount = walletsRepository.getWallets().reduce(0) { $0 + $1.amountInCurrentFiat }
            let withTokens = fiatAmount > 0
            if withTokens {
                analyticsManager.log(event: AmplitudeEvent.sendViewed(lastScreen: "main_screen"))
                sendCoordinator = SendCoordinator(rootViewController: navigationController, preChosenWallet: nil, hideTabBar: true, allowSwitchingMainAmountType: true)
                sendCoordinator?.start()
                    .sink { [weak self, weak navigationController] result in
                        switch result {
                        case let .sent(model):
                            navigationController?.popToRootViewController(animated: true)
                            self?.routeToSendTransactionStatus(model: model)
                        case .cancelled:
                            break
                        }
                    }
                    .store(in: &subscriptions)
            } else {
                emptySendCoordinator = SendEmptyCoordinator(navigationController: navigationController)
                emptySendCoordinator?.start()
                    .sink(receiveValue: { [weak self] _ in
                        self?.emptySendCoordinator = nil
                    })
                    .store(in: &subscriptions)
            }
        case .cashOut:
            if available(.sellScenarioEnabled) {
                analyticsManager.log(event: AmplitudeEvent.actionButtonClick(isSellEnabled: sellDataService.isAvailable))
                
                sellCoordinator = SellCoordinator(navigationController: navigationController)
                sellCoordinator?.start()
                    .sink { [weak self] result in
                        switch result {
                        case .completed:
                            self?.tabBarController.changeItem(to: .history)
                        case .none:
                            break
                        }
                    }
                    .store(in: &subscriptions)
            }
        }
    }

    private func routeToSendTransactionStatus(model: SendTransaction) {
        sendStatusCoordinator = SendTransactionStatusCoordinator(parentController: tabBarController, transaction: model)
        
        sendStatusCoordinator?
            .start()
            .sink(receiveValue: { })
            .store(in: &subscriptions)
    }
}
