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

final class TabBarCoordinator: Coordinator<Void> {

    // Dependencies
    private unowned var window: UIWindow!

    private let tabBarController: TabBarController
    @Injected private var userWalletManager: UserWalletManager

    private let closeSubject = PassthroughSubject<Void, Never>()

    // MARK: - Init

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
        listenMiddleButton()
        listenWallet()
    }
    
    // MARK: - Life cycle
    
    override func start() -> AnyPublisher<Void, Never> {
        let homeNavigation = UINavigationController()
        let homeCoordinator = HomeCoordinator(navigationController: homeNavigation)
        coordinate(to: homeCoordinator)
            .sink(receiveValue: {})
            .store(in: &subscriptions)
        homeCoordinator.showEarn
            .sink(receiveValue: { [unowned self] in
                tabBarController.changeItem(to: .invest)
            })
            .store(in: &subscriptions)
        tabBarController.homeTabClickedTwicely
            .sink(receiveValue: { [weak homeCoordinator] in
                homeCoordinator?.scrollToTop()
            })
            .store(in: &subscriptions)
        tabBarController.solendTutorialClicked
            .sink(receiveValue: { [weak self] in
                self?.routeToSolendTutorial()
            })
            .store(in: &subscriptions)

        let solendOrHistoryNavigation: UINavigationController
        let historyOrFeedbackNavigation: UINavigationController
        if available(.investSolendFeature) {
            solendOrHistoryNavigation = UINavigationController()
            let solendCoordinator = SolendCoordinator(navigationController: solendOrHistoryNavigation)
            coordinate(to: solendCoordinator)
                .sink(receiveValue: { _ in })
                .store(in: &subscriptions)
            historyOrFeedbackNavigation = UINavigationController(rootViewController: History.Scene())
        } else {
            solendOrHistoryNavigation = UINavigationController(rootViewController: History.Scene())
            historyOrFeedbackNavigation = UINavigationController(rootViewController: History.Scene())
        }

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

        tabBarController.setViewControllers(
            [
                homeNavigation,
                solendOrHistoryNavigation,
                UINavigationController(),
                historyOrFeedbackNavigation,
                settingsNavigation,
            ],
            animated: false
        )
        tabBarController.setupTabs()

        window.rootViewController?.view.hideLoadingIndicatorView()
        window.animate(newRootViewController: tabBarController)

        return closeSubject.prefix(1).eraseToAnyPublisher()
    }

    private func listenMiddleButton() {
        tabBarController.middleButtonClicked
            .sink { [unowned self] in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                let actionsCoordinator = ActionsCoordinator(viewController: tabBarController)
                coordinate(to: actionsCoordinator)
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
            .store(in: &subscriptions)
    }

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
            let sendCoordinator = SendCoordinator(navigationController: navigationController, pubKey: nil)
            coordinate(to: sendCoordinator)
                .sink(receiveValue: { _ in })
                .store(in: &subscriptions)
        }
    }

    private func routeToSolendTutorial() {
        var view = SolendTutorialView(viewModel: .init())
        view.doneHandler = { [weak self] in
            self?.tabBarController.changeItem(to: .invest)
        }
        let vc = view.asViewController()
        vc.modalPresentationStyle = .fullScreen
        tabBarController.present(vc, animated: true)
    }

    private func listenWallet() {
        userWalletManager.$wallet
            .sink { [weak self] wallet in
                if wallet == nil {
                    self?.closeSubject.send()
                }
            }
            .store(in: &subscriptions)
    }
}
