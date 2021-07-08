//
//  TransactionsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import Action
import RxCocoa

class TransactionsCollectionView: BECollectionView {
    let transactionsSection: DefaultSection
    let graphViewModel: WalletGraphViewModel
    let analyticsManager: AnalyticsManagerType
    let scanQrCodeAction: CocoaAction
    let wallet: Driver<Wallet?>
    let solPubkey: Driver<String?>
    
    init(
        transactionViewModel: BEListViewModelType,
        graphViewModel: WalletGraphViewModel,
        analyticsManager: AnalyticsManagerType,
        scanQrCodeAction: CocoaAction,
        wallet: Driver<Wallet?>,
        solPubkey: Driver<String?>
    ) {
        self.analyticsManager = analyticsManager
        self.graphViewModel = graphViewModel
        self.scanQrCodeAction = scanQrCodeAction
        self.wallet = wallet
        self.solPubkey = solPubkey
        
        transactionsSection = .init(
            index: 0,
            viewModel: transactionViewModel,
            graphViewModel: graphViewModel
        )
        super.init(
            header: .init(
                viewType: TransactionsCollectionView.HeaderView.self,
                heightDimension: .estimated(557)
            ),
            sections: [transactionsSection]
        )
    }
    
    override func configureHeaderView(kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        let headerView = super.configureHeaderView(kind: kind, indexPath: indexPath) as? HeaderView
        headerView?.setUp(
            graphViewModel: graphViewModel,
            analyticsManager: analyticsManager,
            scanQrCodeAction: scanQrCodeAction,
            wallet: wallet,
            solPubkey: solPubkey
        )
        return headerView
    }
}
