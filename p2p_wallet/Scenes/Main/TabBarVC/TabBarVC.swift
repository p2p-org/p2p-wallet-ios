//
//  TabBarVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import Intercom
import Resolver
import RxSwift
import UIKit

protocol TabBarNeededViewController: UIViewController {}

final class TabBarVC: BEPagesVC {
    lazy var tabBar = NewTabBar()
    @Injected private var helpCenterLauncher: HelpCenterLauncher
    @Injected private var clipboardManager: ClipboardManagerType
    private var tabBarTopConstraint: NSLayoutConstraint!

    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }

    override func setUp() {
        super.setUp()
        view.backgroundColor = .background

        let homeViewModel = Home.ViewModel()
        let homeVC = Home.ViewController(viewModel: homeViewModel)
        let historyVC = History.Scene()
        let sendTokenVC = SendToken.ViewController(
            viewModel: SendToken.ViewModel(
                walletPubkey: nil,
                destinationAddress: nil,
                relayMethod: .default,
                canGoBack: false
            )
        )
        sendTokenVC.doneHandler = { [weak sendTokenVC, weak self] in
            sendTokenVC?.popToRootViewController(animated: false)
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak homeViewModel] in
                homeViewModel?.scrollToTop()
            }
            self?.moveToPage(0)
            CATransaction.commit()
        }

        let settingsVC = Settings.ViewController(viewModel: Settings.ViewModel(canGoBack: false))

        viewControllers = [
            createNavigationController(rootVC: homeVC),
            createNavigationController(rootVC: historyVC),
            createNavigationController(rootVC: sendTokenVC),
            createNavigationController(rootVC: settingsVC),
        ]

        // disable scrolling
        for view in pageVC.view.subviews where view is UIScrollView {
            (view as! UIScrollView).isScrollEnabled = false
        }

        // tabBar
        view.addSubview(tabBar)
        tabBarTopConstraint = tabBar.autoPinEdge(.top, to: .bottom, of: view)
        tabBarTopConstraint.isActive = false
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)

        // configure tabBar
        configureTabBar()

        // fix constraint
        containerView.autoPinEdge(.bottom, to: .top, of: tabBar)

        pageControl.isHidden = true

        // action
        currentPage = -1
        moveToPage(0)
    }

    override func setUpContainerView() {
        view.addSubview(containerView)
        containerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
    }

    // MARK: - Helpers

    private func createNavigationController(rootVC: UIViewController) -> UINavigationController {
        let nc = NavigationController(rootViewController: rootVC)
        nc.hideTabBarHandler = { [weak self] shouldHide in
            self?.hideTabBar(shouldHide)
        }
        return nc
    }

    private func hideTabBar(_ shouldHide: Bool) {
        tabBarTopConstraint.isActive = shouldHide
        containerView.setNeedsLayout()
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func configureTabBar() {
        tabBar.stackView.addArrangedSubviews([
            buttonTabBarItem(image: .tabbarWallet, title: L10n.wallet, item: .wallet),
            buttonTabBarItem(image: .tabbarHistory, title: L10n.history, item: .history),
            buttonTabBarItem(image: .buttonSend.withRenderingMode(.alwaysTemplate), title: L10n.send, item: .send),
            buttonTabBarItem(image: .tabbarFeedback, title: L10n.feedback, item: .feedback),
            buttonTabBarItem(image: .tabbarSettings, title: L10n.settings, item: .settings),
        ])
    }

    private func buttonTabBarItem(image: UIImage, title: String, item: Item) -> UIView {
        let itemView = TabBarItemView(forAutoLayout: ())
        itemView.tintColor = .tabbarUnselected
        itemView.imageView.image = image
        itemView.titleLabel.text = title
        return itemView
            .padding(.init(x: 0, y: 16))
            .withTag(item.rawValue)
            .onTap(self, action: #selector(switchTab(_:)))
    }

    @objc func switchTab(_ gesture: UIGestureRecognizer) {
        guard let tag = gesture.view?.tag, let item = Item(rawValue: tag) else { return }
        moveToItem(item)
    }

    func moveToItem(_ item: Item) {
        moveToPage(item.rawValue)
    }

    override func moveToPage(_ index: Int) {
        guard currentPage != index else { return }
        guard index != 10 else { return helpCenterLauncher.launch() }
        super.moveToPage(index)
        guard let item = (tabBar.stackView.arrangedSubviews.first { $0.tag == index }) else { return }

        item.subviews.first?.tintColor = .tabbarSelected
        tabBar.stackView.arrangedSubviews
            .filter { $0.tag != index }
            .forEach { $0.subviews.first?.tintColor = .tabbarUnselected }

        setNeedsStatusBarAppearanceUpdate()
    }
}

private final class NavigationController: UINavigationController {
    var hideTabBarHandler: ((Bool) -> Void)?

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard viewControllers.count >= 1 else {
            super.pushViewController(viewController, animated: animated)
            return
        }

        // check current view controller and pushing view controller
        let currentVC = viewControllers.last!
        let pushingVC = viewController

        handleShowHideTabBar(previousVC: currentVC, nextVC: pushingVC)

        super.pushViewController(viewController, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        guard viewControllers.count >= 2 else {
            return super.popViewController(animated: animated)
        }
        // check previous view controller and popping view controller
        let poppingVC = viewControllers.last!
        let parentVC = viewControllers[viewControllers.count - 2]

        handleShowHideTabBar(previousVC: poppingVC, nextVC: parentVC)

        return super.popViewController(animated: animated)
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        guard viewControllers.count >= 2 else {
            return super.popToRootViewController(animated: animated)
        }
        handleShowHideTabBar(previousVC: viewControllers.last!, nextVC: viewControllers.first!)
        return super.popToRootViewController(animated: animated)
    }

    private func handleShowHideTabBar(previousVC: UIViewController, nextVC: UIViewController) {
        // if previous view controller is already TabBarNeededViewController
        if previousVC is TabBarNeededViewController {
            // if next VC is not TabBarNeededViewController, hide the tabBar
            if !(nextVC is TabBarNeededViewController) {
                hideTabBarHandler?(true)
            }
            // else (next VC is also TabBarNeededViewController) do nothing, as showing has already been done in previous step
        }
        // if current view controller is not TabBarNeededViewController
        else {
            // if next VC is TabBarNeededViewController, show the tabBar
            if nextVC is TabBarNeededViewController {
                hideTabBarHandler?(false)
            }
            // else (next VC is also not TabBarNeededViewController) do nothing, as hiding has already been done in previous step
        }
    }
}

extension UIViewController {
    func tabBar() -> TabBarVC? {
        guard let vc = self as? TabBarVC else { return parent?.tabBar() }
        return vc
    }
}

extension TabBarVC {
    enum Item: Int {
        case wallet = 0
        case history = 1
        case send = 2
        case feedback = 10
        case settings = 3
    }
}
