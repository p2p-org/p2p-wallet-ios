//
//  SendToken.BaseViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation

extension SendToken {
    class BaseViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Subviews
        lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton.onTap(self, action: #selector(back))
            return navigationBar
        }()
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        }
    }
}
