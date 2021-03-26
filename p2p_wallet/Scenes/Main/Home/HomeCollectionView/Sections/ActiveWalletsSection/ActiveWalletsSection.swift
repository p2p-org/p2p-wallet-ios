//
//  ActiveWalletsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import BECollectionView
import Action

class ActiveWalletsSection: BECollectionViewSection {
    var openProfileAction: CocoaAction?
    var walletCellEditAction: Action<Wallet, Void>?
    
    init(index: Int, viewModel: WalletsListViewModelType) {
        super.init(
            index: index,
            layout: .init(
                header: .init(
                    identifier: "ActiveWalletsSectionHeaderView",
                    viewClass: HeaderView.self
                ),
                cellType: HomeWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .absolute(45),
                contentInsets: NSDirectionalEdgeInsets(top: 0, leading: .defaultPadding, bottom: 0, trailing: .defaultPadding),
                horizontalInterItemSpacing: .fixed(16),
                background: BackgroundView.self
            ),
            viewModel: viewModel,
            limit: {
                Array($0.prefix(4))
            }
        )
    }
    
    override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
        let view = super.configureHeader(indexPath: indexPath) as? HeaderView
        view?.openProfileAction = openProfileAction
        return view
    }
    
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: BECollectionViewItem) -> BECollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item) as! HomeWalletCell
        cell.editAction = CocoaAction { [weak self] in
            self?.walletCellEditAction?.execute(item.value as! Wallet)
            return .just(())
        }
        cell.hideAction = CocoaAction { [weak self] in
            let viewModel = self?.viewModel as? WalletsListViewModelType
            viewModel?.toggleWalletVisibility(item.value as! Wallet)
            return .just(())
        }
        return cell
    }
}
