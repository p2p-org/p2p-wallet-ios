//
//  SolanaBuyToken.Scene.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation

extension SolanaBuyToken {
    class Scene: BEScene {
        @BENavigationBinding private var viewModel: SolanaBuyTokenSceneModel!
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                NewWLNavigationBar(title: "\(L10n.buy) Solana")
                UIView.spacer
            }
        }
    }
}
