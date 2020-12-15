//
//  TabBarVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class TabBarVC: BEPagesVC {
    
    let selectedColor: UIColor = .textBlack
    let unselectedColor: UIColor = .a4a4a4
    
    lazy var tabBar = TabBar(cornerRadius: 20)
    
    override func setUp() {
        super.setUp()
        // pages
        viewControllers = [
            BENavigationController(rootViewController: MainVC()),
            BENavigationController(rootViewController: InvestmentsVC()),
            BENavigationController(rootViewController: IntroVC()),
            BENavigationController(rootViewController: ProfileVC())
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
    
    override func bind() {
        super.bind()
        // connect websocket
        SolanaSDK.Socket.shared.connect()
    }
    
    // MARK: - Helpers
    private func configureTabBar() {
        let firstTabItem = buttonTabBarItem(image: .tabbarWallet, tag: 0)
        let secondTabItem = buttonTabBarItem(image: .tabbarThunderbolt, tag: 1)
        let thirdTabItem = buttonTabBarItem(image: .tabbarSearch, tag: 2)
        let forthTabItem = buttonTabBarItem(image: .tabbarProfile, tag: 3)
        
        tabBar.stackView.addArrangedSubviews([
            .spacer,
            firstTabItem,
            secondTabItem,
            thirdTabItem,
            forthTabItem,
            .spacer
        ])
    }
    
    private func buttonTabBarItem(image: UIImage, tag: Int) -> UIView {
        let button = UIImageView(width: 24, height: 24)
        button.image = image
        button.tintColor = unselectedColor
//        button.touchAreaEdgeInsets = UIEdgeInsets(inset: -10)
//        button.addTarget(self, action: #selector(switchTab(button:)), for: .touchUpInside)
        let view = button.padding(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        view.tag = tag
        return view.onTap(self, action: #selector(switchTab(_:)))
    }
    
    @objc func switchTab(_ gesture: UIGestureRecognizer) {
        let tag = gesture.view!.tag
        
        // show profile modal
        if tag == 3 {
            present(ProfileVC(), animated: true, completion: nil)
            return
        }
        
        // or switch page
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
        items.first {$0.tag == currentPage}?.subviews.first?.tintColor = selectedColor
        
        items.filter {$0.tag != currentPage}.forEach {$0.subviews.first?.tintColor = unselectedColor}
    }
}
