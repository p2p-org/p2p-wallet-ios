//
//  TabBarController.swift
//  p2p_wallet
//
//  Created by Ivan on 09.07.2022.
//

import Resolver
import UIKit

final class TabBarController: UITabBarController {
    @Injected private var helpCenterLauncher: HelpCenterLauncher

    private var sendTokenCoordinator: SendToken.Coordinator!

    init() {
        super.init(nibName: nil, bundle: nil)
        object_setClass(tabBar, CustomTabBar.self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        setupViewControllers()
        setupTabs()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Seems to be a bug in iOS 13 with stackedLayoutAppearance (set in AppDelegate), label is shrinked so we need to update its size
        if #available(iOS 13, *) {
            tabBar.subviews.forEach { bar in
                bar.subviews.compactMap { $0 as? UILabel }.forEach {
                    $0.sizeToFit()
                }
            }
        }
    }

    private func setupViewControllers() {
        let homeViewModel = Home.ViewModel()
        let homeVC = Home.ViewController(viewModel: homeViewModel)
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
            CATransaction.setCompletionBlock { [weak homeViewModel] in
                homeViewModel?.scrollToTop()
            }
            self?.changeItem(to: .wallet)
            CATransaction.commit()
        }
        let sendTokenNavigationVC = sendTokenCoordinator.start(hidesBottomBarWhenPushed: false)

        let settingsVC = Settings.ViewController(viewModel: Settings.ViewModel())

        viewControllers = [
            UINavigationController(rootViewController: homeVC),
            UINavigationController(rootViewController: historyVC),
            sendTokenNavigationVC,
            UIViewController(),
            UINavigationController(rootViewController: settingsVC),
        ]
    }

    private func setupTabs() {
        TabItem.allCases.enumerated().forEach { index, item in
            viewControllers?[index].tabBarItem = UITabBarItem(
                title: item.displayTitle,
                image: item.image,
                selectedImage: item.selectedImage
            )
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

        if TabItem(rawValue: selectedIndex) == .feedback {
            routeToFeedback()
            return false
        }

        return true
    }
}

// MARK: - TabItem

private extension TabItem {
    var image: UIImage {
        switch self {
        case .wallet:
            return .tabBarWallet.withRenderingMode(.alwaysOriginal)
        case .history:
            return .tabBarHistory.withRenderingMode(.alwaysOriginal)
        case .send:
            return .tabBarSend.withRenderingMode(.alwaysOriginal)
        case .feedback:
            return .tabBarFeedback.withRenderingMode(.alwaysOriginal)
        case .settings:
            return .tabBarSettings.withRenderingMode(.alwaysOriginal)
        }
    }

    var selectedImage: UIImage {
        switch self {
        case .wallet:
            return .tabBarSelectedWallet.withRenderingMode(.alwaysOriginal)
        case .history:
            return .tabBarSelectedHistory.withRenderingMode(.alwaysOriginal)
        case .send:
            return .tabBarSelectedSend.withRenderingMode(.alwaysOriginal)
        case .feedback:
            return .tabBarSelectedFeedback.withRenderingMode(.alwaysOriginal)
        case .settings:
            return .tabBarSelectedSettings.withRenderingMode(.alwaysOriginal)
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
