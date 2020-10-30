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
    
    var selectedIndex = -1
    
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
        switchTab(index: gesture.view!.tag)
    }

    func switchTab(index: Int) {
        // scroll to top if index is selected
        if selectedIndex == index {
            return
        }
        
        let items = tabBar.stackView.arrangedSubviews[1..<tabBar.stackView.arrangedSubviews.count - 1]
        
        guard index < items.count else {return}
        
        // change selected index
        selectedIndex = index
        
        // change tabs' color
        items.first {$0.tag == selectedIndex}?.subviews.first?.tintColor = selectedColor
        
        items.filter {$0.tag != selectedIndex}.forEach {$0.subviews.first?.tintColor = unselectedColor}
    }
}
