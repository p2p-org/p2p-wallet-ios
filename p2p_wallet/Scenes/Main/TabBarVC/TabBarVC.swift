//
//  TabBarVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import UIKit
import RxSwift

protocol TabBarNeededViewController: UIViewController {}

class TabBarVC: BEPagesVC {
    lazy var tabBar = NewTabBar()
    private let disposeBag = DisposeBag()
    private var tabBarTopConstraint: NSLayoutConstraint!
    
    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
        
        viewControllers = [
            createNavigationController(rootVC: Home.ViewController(
                viewModel: Home.ViewModel()
            )),
            createNavigationController(rootVC: InvestmentsViewController(
                viewModel: InvestmentsViewModel(
                    newsViewModel: NewsViewModel(),
                    defisViewModel: DefisViewModel()
                )
            )),
            createNavigationController(rootVC: _PlaceholderVC()),
            createNavigationController(rootVC: DAppContainer.ViewController(
                viewModel: DAppContainer.ViewModel(dapp: .fake)
            )),
            createNavigationController(rootVC: _PlaceholderVC())
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
        nc.hideTabBarHandler = {[weak self] shouldHide in
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
            .spacer,
            buttonTabBarItem(image: .tabbarWallet, title: L10n.wallet, tag: 0),
            buttonTabBarItem(image: .tabbarTransaction, title: L10n.earn, tag: 1),
            buttonTabBarItem(image: .tabbarPlus, title: L10n.buy, tag: 2),
            buttonTabBarItem(image: .tabbarPlanet, title: L10n.dApps, tag: 3),
            buttonTabBarItem(image: .tabbarInfo, title: L10n.profile, tag: 4),
            .spacer
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
        super.moveToPage(index)
        
        let items = tabBar.stackView.arrangedSubviews[1..<tabBar.stackView.arrangedSubviews.count - 1]
        
        guard index < items.count else {return}
        
        // change tabs' color
        items.first {$0.tag == currentPage}?.subviews.first?.tintColor = .tabbarSelected
        
        items.filter {$0.tag != currentPage}.forEach {$0.subviews.first?.tintColor = .tabbarUnselected}
        
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

private class _PlaceholderVC: BaseVC, TabBarNeededViewController {}
