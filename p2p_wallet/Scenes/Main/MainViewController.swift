//
//  MainViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Foundation
import UIKit
import Action

protocol _MainScenesFactory {
    func makeTabBarVC() -> TabBarVC
}

class MainViewController: BaseVC {
    
    // MARK: - Properties
    let rootViewModel: Root.ViewModel
    let scenesFactory: _MainScenesFactory
    
    // MARK: - Initializer
    init(rootViewModel: Root.ViewModel, scenesFactory: _MainScenesFactory)
    {
        self.rootViewModel = rootViewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        add(child: scenesFactory.makeTabBarVC())
    }
}
