//
//  TabBarVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

protocol TabBarScenesFactory {
    func makeHomeViewController() -> Home.ViewController
    func makeInvestmentsViewController() -> InvestmentsViewController
    func makeDAppContainerViewController(dapp: DApp) -> DAppContainer.ViewController // TODO: - Replace by DAppsCollectionViewController later
}

class TabBarVC: BEPagesVC {
    lazy var tabBar = NewTabBar()
    
    let scenesFactory: TabBarScenesFactory
    init(scenesFactory: TabBarScenesFactory) {
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        // pages
        let mainVC = scenesFactory.makeHomeViewController()
        let investmentsVC = scenesFactory.makeInvestmentsViewController()
        let dAppContainerVC = scenesFactory.makeDAppContainerViewController(dapp: .fake)
        
        viewControllers = [
            BENavigationController(rootViewController: mainVC),
            BENavigationController(rootViewController: investmentsVC),
            BENavigationController(rootViewController: BaseVC()),
            BENavigationController(rootViewController: dAppContainerVC),
            BENavigationController(rootViewController: BaseVC())
        ]
        
        // disable scrolling
        for view in pageVC.view.subviews where view is UIScrollView {
            (view as! UIScrollView).isScrollEnabled = false
        }
        
        // tabBar
        view.addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
        // configure tabBar
        configureTabBar()
        
        // fix constraint
        containerView.constraintToSuperviewWithAttribute(.bottom)?
            .isActive = false
        containerView.autoPinEdge(.bottom, to: .top, of: tabBar, withOffset: 20)
        
        pageControl.isHidden = true
        
        // action
        currentPage = -1
        moveToPage(0)
    }
    
    // MARK: - Helpers
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
