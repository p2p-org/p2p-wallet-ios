//
//  TabBarController.swift
//  p2p_wallet
//
//  Created by Ivan on 09.07.2022.
//

import AnalyticsManager
import Combine
import KeyAppUI
import Resolver
import SwiftUI
import UIKit

final class TabBarController: UITabBarController {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var helpCenterLauncher: HelpCenterLauncher

    private var cancellables = Set<AnyCancellable>()

    private var solendCoordinator: SolendCoordinator!
    private var homeCoordinator: HomeCoordinator!
    private var actionsCoordinator: ActionsCoordinator?
    private var settingsCoordinator: SettingsCoordinator!
    private var buyCoordinator: BuyCoordinator?
    private var emptySendCoordinator: SendEmptyCoordinator?
    private var sendCoordinator: SendCoordinator?
    private var sendStatusCoordinator: SendTransactionStatusCoordinator?

    @Injected private var walletsRepository: WalletsRepository

    private var customTabBar: CustomTabBar { tabBar as! CustomTabBar }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTabBarAppearance()
        setValue(CustomTabBar(frame: tabBar.frame), forKey: "tabBar")
        delegate = self

        setupViewControllers()
        setupTabs()

        bind()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        tabBar.subviews.forEach { bar in
            bar.subviews.compactMap { $0 as? UILabel }.forEach {
                $0.adjustsFontSizeToFitWidth = true
            }
        }
    }

    private func bind() {
        customTabBar.middleButtonClicked
            .sink(receiveValue: { [unowned self] in
                analyticsManager.log(event: AmplitudeEvent.actionButtonClick)

                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                actionsCoordinator = ActionsCoordinator(viewController: self)
                actionsCoordinator?.start()
                    .sink(receiveValue: { [weak self] result in
                        switch result {
                        case .cancel:
                            self?.actionsCoordinator = nil
                        case let .action(type):
                            self?.handleAction(type)
                            self?.actionsCoordinator = nil
                        }
                    })
                    .store(in: &cancellables)
            })
            .store(in: &cancellables)
    }

    private func handleAction(_ action: ActionsView.Action) {
        guard let navigationController = selectedViewController as? UINavigationController else { return }

        switch action {
        case .buy:
            let buyCoordinator = BuyCoordinator(
                navigationController: navigationController,
                context: .fromHome
            )
            self.buyCoordinator = buyCoordinator
            buyCoordinator.start()
                .sink(receiveValue: {})
                .store(in: &cancellables)
        case .receive:
            break
        case .swap:
            let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
            let vc = OrcaSwapV2.ViewController(viewModel: vm)
            vc.doneHandler = {
                navigationController.popToRootViewController(animated: true)
            }
            navigationController.show(vc, sender: nil)
        case .send:
            let fiatAmount = walletsRepository.getWallets().reduce(0) { $0 + $1.amountInCurrentFiat }
            let withTokens = fiatAmount > 0
            if withTokens {
                analyticsManager.log(event: AmplitudeEvent.sendViewed(lastScreen: "main_screen"))
                sendCoordinator = SendCoordinator(rootViewController: navigationController, preChosenWallet: nil, hideTabBar: true)
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
                    .store(in: &cancellables)
            } else {
                emptySendCoordinator = SendEmptyCoordinator(navigationController: navigationController)
                emptySendCoordinator?.start()
                    .sink(receiveValue: { [weak self] _ in
                        self?.emptySendCoordinator = nil
                    })
                    .store(in: &cancellables)
            }
            analyticsManager.log(event: AmplitudeEvent.sendViewed(lastScreen: "main_screen"))
        case .cashOut:
            sellCoordinator = SellCoordinator(navigationController: navigationController)
            sellCoordinator?.start().sink(receiveValue: { _ in }).store(in: &cancellables)
        }
    }

    private func setUpTabBarAppearance() {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.backgroundColor = Asset.Colors.snow.color
        standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: Asset.Colors.mountain.color,
        ]
        standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: Asset.Colors.night.color,
        ]
        standardAppearance.stackedLayoutAppearance.normal.iconColor = Asset.Colors.mountain.color
        standardAppearance.stackedLayoutAppearance.selected.iconColor = Asset.Colors.night.color
        standardAppearance.stackedItemPositioning = .automatic
        standardAppearance.shadowImage = nil
        standardAppearance.shadowColor = nil
        UITabBar.appearance().standardAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = standardAppearance
        }
    }

    private func setupViewControllers() {
        let homeNavigation = UINavigationController()
        homeCoordinator = HomeCoordinator(navigationController: homeNavigation, tabBarController: self)
        homeCoordinator.start()
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)

        let solendOrHistoryNavigation: UINavigationController
        let historyOrFeedbackNavigation: UINavigationController
        if available(.investSolendFeature) {
            solendOrHistoryNavigation = UINavigationController()
            solendCoordinator = SolendCoordinator(navigationController: solendOrHistoryNavigation)
            solendCoordinator.start()
                .sink(receiveValue: { _ in })
                .store(in: &cancellables)
            historyOrFeedbackNavigation = UINavigationController(rootViewController: History.Scene())
        } else {
            solendOrHistoryNavigation = UINavigationController(rootViewController: History.Scene())
            historyOrFeedbackNavigation = UINavigationController(rootViewController: History.Scene())
        }

        let settingsNavigation: UINavigationController
        if available(.settingsFeature) {
            settingsNavigation = UINavigationController()
            settingsCoordinator = SettingsCoordinator(navigationController: settingsNavigation)
            settingsCoordinator.start()
                .sink(receiveValue: { _ in })
                .store(in: &cancellables)
        } else {
            settingsNavigation = UINavigationController(
                rootViewController: Settings.ViewController(viewModel: Settings.ViewModel())
            )
        }

        viewControllers = [
            homeNavigation,
            solendOrHistoryNavigation,
            UINavigationController(),
            historyOrFeedbackNavigation,
            settingsNavigation,
        ]
    }

    private func setupTabs() {
        TabItem.allCases.enumerated().forEach { index, item in
            if item == .actions {
                viewControllers?[index].tabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)
            } else {
                viewControllers?[index].tabBarItem = UITabBarItem(
                    title: item.displayTitle,
                    image: item.image,
                    selectedImage: item.image
                )
            }
        }
    }

    private func routeToFeedback() {
        helpCenterLauncher.launch()
    }

    private func routeToSolendTutorial() {
        var view = SolendTutorialView(viewModel: .init())
        view.doneHandler = { [weak self] in
            self?.changeItem(to: .invest)
        }
        let vc = UIHostingControllerWithoutNavigation(rootView: view)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    private func routeToSendTransactionStatus(model: SendTransaction) {
        sendStatusCoordinator = SendTransactionStatusCoordinator(parentController: self, transaction: model)
        
        sendStatusCoordinator?
            .start()
            .sink(receiveValue: { })
            .store(in: &cancellables)
    }

    func changeItem(to item: TabItem) {
        guard let viewControllers = viewControllers,
              item.rawValue < viewControllers.count
        else { return }
        let viewController = viewControllers[item.rawValue]
        selectedIndex = item.rawValue
        _ = tabBarController(self, shouldSelect: viewController)
    }
}

// MARK: - UITabBarControllerDelegate

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController) else {
            return true
        }

        if TabItem(rawValue: selectedIndex) == .history, !available(.investSolendFeature) {
            routeToFeedback()
            return false
        }
        customTabBar.updateSelectedViewPositionIfNeeded()
        if TabItem(rawValue: selectedIndex) == .invest {
            if available(.investSolendFeature), !Defaults.isSolendTutorialShown, available(.solendDisablePlaceholder) {
                routeToSolendTutorial()
                return false
            }
        }

        if TabItem(rawValue: selectedIndex) == .wallet,
           (viewController as! UINavigationController).viewControllers.count == 1,
           self.selectedIndex == selectedIndex
        {
            homeCoordinator?.scrollToTop()
        }

        return true
    }
}

// MARK: - TabItem

private extension TabItem {
    var image: UIImage {
        switch self {
        case .wallet:
            return .tabBarSelectedWallet
        case .invest:
            return available(.investSolendFeature) ? .tabBarEarn : .tabBarHistory
        case .actions:
            return UIImage()
        case .history:
            return available(.investSolendFeature) ? .tabBarHistory : .tabBarFeedback
        case .settings:
            return .tabBarSettings
        }
    }

    var displayTitle: String {
        switch self {
        case .wallet:
            return L10n.wallet
        case .invest:
            return available(.investSolendFeature) ? L10n.earn : L10n.history
        case .actions:
            return ""
        case .history:
            return available(.investSolendFeature) ? L10n.history : L10n.feedback
        case .settings:
            return L10n.settings
        }
    }
}
