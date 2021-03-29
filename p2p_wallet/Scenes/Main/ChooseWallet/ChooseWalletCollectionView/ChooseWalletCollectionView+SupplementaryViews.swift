//
//  ChooseWalletCollectionView+SupplementaryViews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation

extension ChooseWalletCollectionView {
    class FirstSectionHeaderView: WLSectionHeaderView {
        override func commonInit() {
            super.commonInit()
            setUp(headerTitle: L10n.yourTokens, headerFont: .systemFont(ofSize: 15), headerColor: .a3a5ba)
        }
    }
    
    class SecondSectionHeaderView: WLSectionHeaderView {
        override func commonInit() {
            super.commonInit()
            setUp(headerTitle: L10n.allTokens, headerFont: .systemFont(ofSize: 15), headerColor: .a3a5ba)
        }
    }
}
