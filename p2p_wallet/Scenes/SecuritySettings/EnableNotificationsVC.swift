//
//  EnableNotificationsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class EnableNotificationsVC: SecuritySettingVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    override var nextVC: UIViewController {
        BaseVC()
    }
}
