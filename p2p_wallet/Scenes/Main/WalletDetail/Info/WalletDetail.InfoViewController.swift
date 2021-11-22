//
//  WalletDetail.InfoViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import UIKit

extension WalletDetail {
    class InfoViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        override func setUp() {
            super.setUp()
            let label = UILabel(text: "Info")
            view.addSubview(label)
            label.autoCenterInSuperview()
        }
    }
}
