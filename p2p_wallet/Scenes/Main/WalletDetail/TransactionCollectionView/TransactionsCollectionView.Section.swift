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
    class DefaultSection: BECollectionViewSectionBase {
        init(index: Int) {
            super.init(
                index: index,
                layout: .init(
                    header: .init(
                        viewClass: SectionHeaderView.self,
                        heightDimension: .estimated(15)
                    ),
                    cellType: TransactionCell.self,
                    emptyCellType: WLEmptyCell.self,
                    interGroupSpacing: 1,
                    itemHeight: .estimated(85)
                )
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
    }
}
