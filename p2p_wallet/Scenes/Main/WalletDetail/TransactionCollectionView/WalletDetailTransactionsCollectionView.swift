//
//  WalletDetailTransactionsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import Action

class WalletDetailTransactionsCollectionView: BECollectionView {
    let transactionsSection: WalletDetailTransactionsSection
    let analyticsManager: AnalyticsManagerType
    
    var scanQrCodeAction: CocoaAction? {
        get {
            transactionsSection.scanQrCodeAction
        }
        set {
            transactionsSection.scanQrCodeAction = newValue
        }
    }
    
    var wallet: Wallet? {
        get {
            transactionsSection.wallet
        }
        set {
            transactionsSection.wallet = newValue
        }
    }
    
    var solPubkey: String? {
        get {
            transactionsSection.solPubkey
        }
        set {
            transactionsSection.solPubkey = newValue
        }
    }
    
    init(transactionViewModel: BEListViewModelType, graphViewModel: WalletGraphViewModel, analyticsManager: AnalyticsManagerType) {
        self.analyticsManager = analyticsManager
        transactionsSection = .init(
            index: 0,
            viewModel: transactionViewModel,
            graphViewModel: graphViewModel,
            analyticsManager: analyticsManager
        )
        super.init(sections: [
            transactionsSection
        ])
    }
}
