//
//  TabBarVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class TabBarVC: BaseVC {
    let selectedColor: UIColor = .textBlack
    let unselectedColor: UIColor = .a4a4a4
    
    lazy var tabBar = TabBar(cornerRadius: 20)
    
    override func setUp() {
        super.setUp()
        view.addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
//        tabBar.autoSetDimension(.height, toSize: 60)
        
        // configure tabBar
        configureTabBar()
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
        tabBar.layoutSubviews()
    }
    
    private func buttonTabBarItem(image: UIImage, tag: Int) -> UIView {
        let button = UIImageView(width: 24, height: 24)
        button.image = image
        button.tintColor = unselectedColor
        button.tag = tag
//        button.touchAreaEdgeInsets = UIEdgeInsets(inset: -10)
//        button.addTarget(self, action: #selector(switchTab(button:)), for: .touchUpInside)
        return button.padding(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }
}
