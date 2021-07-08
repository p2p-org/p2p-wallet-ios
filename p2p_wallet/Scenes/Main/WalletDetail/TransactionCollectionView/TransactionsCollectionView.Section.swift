//
//  TransactionsCollectionView.Section.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import RxSwift
import Action

extension TransactionsCollectionView {
    class DefaultSection: BECollectionViewSection {
        private var graphViewModel: WalletGraphViewModel
        init(
            index: Int,
            viewModel: BEListViewModelType,
            graphViewModel: WalletGraphViewModel
        ) {
            self.graphViewModel = graphViewModel
            super.init(
                index: index,
                layout: .init(
                    cellType: TransactionCell.self,
                    emptyCellType: WLEmptyCell.self,
                    interGroupSpacing: 1,
                    itemHeight: .estimated(85)
                ),
                viewModel: viewModel
            )
        }
        
        override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: BECollectionViewItem) -> UICollectionViewCell {
            let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
            if let cell = cell as? WLEmptyCell {
                cell.titleLabel.text = L10n.noTransactionsYet
                cell.subtitleLabel.text = L10n.youHaveNotMadeAnyTransactionYet
                cell.imageView.image = .transactionEmpty
            }
            return cell
        }
        
        override func reload() {
            super.reload()
            graphViewModel.reload()
        }
    }
}
