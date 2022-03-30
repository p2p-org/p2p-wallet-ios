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

class TabBarVC: BEPagesVC {
    lazy var tabBar = NewTabBar()
    @Injected private var helpCenterLauncher: HelpCenterLauncher
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
            sendTokenNavigationVC,
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
            .spacer,
            buttonTabBarItem(image: .tabbarWallet, title: L10n.wallet, tag: 0),
            buttonTabBarItem(image: .buttonSend.withRenderingMode(.alwaysTemplate), title: L10n.send, tag: 1),
            buttonTabBarItem(image: .tabbarFeedback, title: L10n.feedback, tag: 10),
            buttonTabBarItem(image: .tabbarSettings, title: L10n.settings, tag: 2),
            .spacer,
        ])
    }

    private func buttonTabBarItem(image: UIImage, title: String, tag: Int) -> UIView {
        let item = TabBarItemView(forAutoLayout: ())
        item.tintColor = .tabbarUnselected
        item.imageView.image = image
        item.titleLabel.text = title
        return item
            .padding(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
            .withTag(tag)
            .onTap(self, action: #selector(switchTab(_:)))
    }

    @objc func switchTab(_ gesture: UIGestureRecognizer) {
        let tag = gesture.view!.tag

        moveToPage(tag)
    }

    override func moveToPage(_ index: Int) {
        // scroll to top if index is selected
        if currentPage == index {
            return
        }

        guard index != 10 else {
            return helpCenterLauncher.launch()
        }

        super.moveToPage(index)

        let items = tabBar.stackView.arrangedSubviews[1 ..< tabBar.stackView.arrangedSubviews.count - 1]

        guard index < items.count else { return }

        // change tabs' color
        items.first { $0.tag == currentPage }?.subviews.first?.tintColor = .tabbarSelected

        items.filter { $0.tag != currentPage }.forEach { $0.subviews.first?.tintColor = .tabbarUnselected }
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
