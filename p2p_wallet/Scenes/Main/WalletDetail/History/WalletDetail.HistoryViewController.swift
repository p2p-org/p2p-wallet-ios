//
//  WalletDetail.HistoryViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import BECollectionView

extension WalletDetail {
    class HistoryViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: WalletDetailViewModelType
        
        // MARK: - Subviews
        private lazy var collectionView: TransactionsCollectionView = {
            let collectionView = TransactionsCollectionView(
                transactionViewModel: viewModel.transactionsViewModel,
                graphViewModel: viewModel.graphViewModel,
                wallet: viewModel.walletDriver,
                nativePubkey: viewModel.nativePubkey
            )
            collectionView.delegate = self
            return collectionView
        }()
        
        // MARK: - Initializers
        override func setUp() {
            super.setUp()
            view.addSubview(collectionView)
            collectionView.autoPinEdgesToSuperviewEdges()
            
            collectionView.refresh()
        }
    }
}

extension WalletDetail.HistoryViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let transaction = item as? SolanaSDK.ParsedTransaction else {return}
        viewModel.showTransaction(transaction)
    }
}
