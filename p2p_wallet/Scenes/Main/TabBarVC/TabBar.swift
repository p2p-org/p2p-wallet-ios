//
//  TabBar.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

extension TabBarVC {
    class TabBar: BERoundedCornerShadowView {
        override func commonInit() {
            super.commonInit()
            stackView.spacing = 0
            stackView.distribution = .fillEqually
        }
        
        override func layoutStackView() {
            stackView.autoPinEdgesToSuperviewSafeArea(with: contentInset)
        }
        
        override func roundCorners() {
            mainView.roundCorners([.topLeft, .topRight], radius: mainViewCornerRadius)
        }
    }
}
