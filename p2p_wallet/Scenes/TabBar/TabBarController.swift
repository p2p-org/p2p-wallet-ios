//
//  TabBarController.swift
//  p2p_wallet
//
//  Created by Ivan on 09.07.2022.
//

import Combine
import KeyAppUI
import Resolver
import UIKit

final class TabBarController: UITabBarController {
    @Injected private var helpCenterLauncher: HelpCenterLauncher

    private var cancellables = Set<AnyCancellable>()

    private var homeCoordinator: HomeCoordinator?
    private var sendTokenCoordinator: SendToken.Coordinator!

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTabBarAppearance()
        setValue(CustomTabBar(frame: tabBar.frame), forKey: "tabBar")
        delegate = self

        setupViewControllers()
        setupTabs()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tabBar.subviews.forEach { bar in
            bar.subviews.compactMap { $0 as? UILabel }.forEach {
                $0.sizeToFit()
            }
        }
    }

    private func setUpTabBarAppearance() {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.backgroundColor = Asset.Colors.snow.color
//        standardAppearance.backgroundEffect = UIBlurEffect(style: .regular)
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
        homeCoordinator = HomeCoordinator(navigationController: homeNavigation)
        homeCoordinator?.start()
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)

        let historyVC = History.Scene()

        let vm = SendToken.ViewModel(
            walletPubkey: nil,
            destinationAddress: nil,
            relayMethod: .default,
            canGoBack: false
        )
        sendTokenCoordinator = SendToken.Coordinator(viewModel: vm, navigationController: nil)
        sendTokenCoordinator.doneHandler = { [weak self] in
            CATransaction.begin()
//            CATransaction.setCompletionBlock { [weak homeViewModel] in
//                homeViewModel?.scrollToTop()
//            }
            self?.changeItem(to: .wallet)
            CATransaction.commit()
        }
        let sendTokenNavigationVC = sendTokenCoordinator.start(hidesBottomBarWhenPushed: false)

        let settingsVC = Settings.ViewController(viewModel: Settings.ViewModel())

        viewControllers = [
            homeNavigation,
            UINavigationController(rootViewController: historyVC),
            sendTokenNavigationVC,
            UIViewController(),
            UINavigationController(rootViewController: settingsVC),
        ]
    }

    private func setupTabs() {
        TabItem.allCases.enumerated().forEach { index, item in
            if item == .send {
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

    func routeToFeedback() {
        helpCenterLauncher.launch()
    }

    func changeItem(to item: TabItem) {
        selectedIndex = item.rawValue
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

        if TabItem(rawValue: selectedIndex) == .feedback || TabItem(rawValue: selectedIndex) == .send {
            routeToFeedback()
            return false
        }

        (tabBar as! CustomTabBar).updateSelectedViewPositionIfNeeded()

        return true
    }
}

// MARK: - TabItem

private extension TabItem {
    var image: UIImage {
        switch self {
        case .wallet:
            return .tabBarSelectedWallet
        case .history:
            return .tabBarHistory
        case .send:
            return UIImage()
        case .feedback:
            return .tabBarFeedback
        case .settings:
            return .tabBarSettings
        }
    }

    var displayTitle: String {
        switch self {
        case .wallet:
            return L10n.wallet
        case .history:
            return L10n.history
        case .send:
            return L10n.send
        case .feedback:
            return L10n.feedback
        case .settings:
            return L10n.settings
        }
    }

    var hideTabBar: Bool {
        self != .settings
    }
}
