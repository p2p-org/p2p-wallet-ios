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

    private var coordinator: SendToken.Coordinator?

    fileprivate var tabBarIsHidden: Bool { tabBarTopConstraint.isActive }

    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }

    override func setUp() {
        super.setUp()
        view.backgroundColor = .background

        let homeViewModel = Home.ViewModel()
        let homeVC = Home.ViewController(viewModel: homeViewModel)
        let historyVC = History.Scene()
        if coordinator == nil {
            let vm = SendToken.ViewModel(
                walletPubkey: nil,
                destinationAddress: nil,
                relayMethod: .default,
                canGoBack: false
            )
            coordinator = SendToken.Coordinator(viewModel: vm, navigationController: nil)
            coordinator?.doneHandler = { [weak self] in
                CATransaction.begin()
                CATransaction.setCompletionBlock { [weak homeViewModel] in
                    homeViewModel?.scrollToTop()
                }
                self?.moveToPage(0)
                CATransaction.commit()
            }
        }
        let sendTokenNavigationVC = coordinator?.start() as! UINavigationController
        sendTokenNavigationVC.delegate = self

        let settingsVC = Settings.ViewController(viewModel: Settings.ViewModel())

        viewControllers = [
            createNavigationController(rootVC: homeVC),
            createNavigationController(rootVC: historyVC),
            sendTokenNavigationVC,
            UINavigationController(rootViewController: settingsVC),
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
        let nc = UINavigationController(rootViewController: rootVC)
        nc.delegate = self
        return nc
    }

    private func hideTabBar(_ shouldHide: Bool) {
        tabBarTopConstraint.isActive = shouldHide
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

// MARK: - UINavigationControllerDelegate

extension TabBarVC: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow _: UIViewController,
        animated _: Bool
    ) {
        let hide = navigationController.viewControllers.count > 1
        guard hide != tabBarIsHidden else { return }
        hideTabBar(hide)
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
