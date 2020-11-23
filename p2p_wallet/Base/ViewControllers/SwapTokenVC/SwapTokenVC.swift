//
//  SwapTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation

class SwapTokenVC: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal(backgroundColor: .vcBackground) }
    override var padding: UIEdgeInsets { UIEdgeInsets(top: 44, left: 16, bottom: 0, right: 16) }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        title = L10n.swap
        
        scrollView.contentView.backgroundColor = .textWhite
        scrollView.contentView.layer.cornerRadius = 16
        scrollView.contentView.layer.masksToBounds = true
    }
}
