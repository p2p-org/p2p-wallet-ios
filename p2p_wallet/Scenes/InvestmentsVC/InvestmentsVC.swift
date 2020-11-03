//
//  InvestmentsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation

class InvestmentsVC: CollectionVC<WalletVC.Section, String, PriceCell> {
    
}

extension InvestmentsVC: TabBarItemVC {
    var scrollView: UIScrollView {collectionView}
}
