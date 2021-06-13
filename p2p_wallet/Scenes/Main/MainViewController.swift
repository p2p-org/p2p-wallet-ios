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
    override var preferredStatusBarStyle: UIStatusBarStyle {
        traitCollection.userInterfaceStyle == .dark ? .lightContent: .darkContent
    }
    
    // MARK: - Properties
    let scenesFactory: _MainScenesFactory
    
    // MARK: - Initializer
    init(scenesFactory: _MainScenesFactory)
    {
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        add(child: scenesFactory.makeTabBarVC())
    }
}
