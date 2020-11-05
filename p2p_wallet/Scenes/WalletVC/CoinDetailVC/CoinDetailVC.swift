//
//  CoinDetailVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

class CoinDetailVC: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .normal()
    }
    
    override func setUp() {
        super.setUp()
        title = "Coin name"
    }
}
