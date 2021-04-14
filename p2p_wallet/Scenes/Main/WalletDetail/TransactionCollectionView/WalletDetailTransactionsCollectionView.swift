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
    
    init(transactionViewModel: BEListViewModelType, graphViewModel: WalletGraphViewModel) {
        transactionsSection = .init(
            index: 0,
            viewModel: transactionViewModel,
            graphViewModel: graphViewModel
        )
        super.init(sections: [
            transactionsSection
        ])
    }
}
