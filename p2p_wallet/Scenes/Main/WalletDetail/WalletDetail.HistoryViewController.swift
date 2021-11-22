//
//  WalletDetail.HistoryViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import Action
import BECollectionView

extension WalletDetail {
    class HistoryViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: WalletDetailViewModelType
        
        // MARK: - Subviews
        private lazy var collectionView: TransactionsCollectionView = {
            let collectionView = TransactionsCollectionView(
                transactionViewModel: viewModel.transactionsViewModel,
                graphViewModel: viewModel.graphViewModel,
                scanQrCodeAction: CocoaAction { [weak self] in
                    self?.receiveTokens()
                    return .just(())
                },
                wallet: viewModel.walletDriver,
                nativePubkey: viewModel.nativePubkey
            )
            collectionView.delegate = self
            return collectionView
        }()
        
        // MARK: - Initializers
        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            view.addSubview(collectionView)
            collectionView.autoPinEdgesToSuperviewEdges()
            
            collectionView.refresh()
        }
        
        // MARK: - Actions
        @objc func receiveTokens() {
            viewModel.receiveTokens()
        }
    }
}

extension WalletDetail.HistoryViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let transaction = item as? SolanaSDK.ParsedTransaction else {return}
        viewModel.showTransaction(transaction)
    }
}
