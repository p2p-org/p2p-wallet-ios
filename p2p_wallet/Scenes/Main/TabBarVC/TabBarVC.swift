//
//  TabBarVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class TabBarVC: BaseVC {
    lazy var tabBar = TabBar(cornerRadius: 20)
    
    override func setUp() {
        super.setUp()
        view.addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
}
