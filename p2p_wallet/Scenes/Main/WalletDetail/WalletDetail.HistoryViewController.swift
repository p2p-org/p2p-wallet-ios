//
//  WalletDetail.HistoryViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation

extension WalletDetail {
    class HistoryViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        override func setUp() {
            super.setUp()
            let label = UILabel(text: "History")
            view.addSubview(label)
            label.autoCenterInSuperview()
        }
    }
}
