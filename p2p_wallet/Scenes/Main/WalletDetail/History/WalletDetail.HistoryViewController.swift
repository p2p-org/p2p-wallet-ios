//
//  WalletDetail.HistoryViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import BECollectionView
import Foundation
import SolanaSwift
import TransactionParser

extension WalletDetail {
    class HistoryViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .embeded
        }

        // MARK: - Dependencies

        private let viewModel: WalletDetailViewModelType

        // MARK: - Subviews

        private lazy var collectionView: TransactionsCollectionView = {
            fatalError()
//            let collectionView = TransactionsCollectionView(
//                transactionViewModel: viewModel.transactionsViewModel,
//                graphViewModel: viewModel.graphViewModel
//            )
//            collectionView.delegate = self
//            return collectionView
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
    }
}

extension WalletDetail.HistoryViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView _: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let transaction = item as? ParsedTransaction else { return }
        viewModel.showTransaction(transaction)
    }
}
