//
//  HiddenWalletsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import BECollectionView
import Action

extension HomeCollectionView {
    class HiddenWalletsSection: WalletsSection {
        var showHideHiddenWalletsAction: CocoaAction?
        
        init(index: Int, viewModel: WalletsListViewModelType) {
            super.init(
                index: index,
                layout: .init(
                    header: .init(
                        identifier: "HiddenWalletsSectionHeaderView",
                        viewClass: HeaderView.self
                    ),
                    cellType: HomeWalletCell.self,
                    interGroupSpacing: 30,
                    itemHeight: .absolute(45),
                    contentInsets: NSDirectionalEdgeInsets(top: 0, leading: .defaultPadding, bottom: .defaultPadding, trailing: .defaultPadding),
                    horizontalInterItemSpacing: .fixed(16)
                ),
                viewModel: viewModel,
                customFilter: { item in
                    guard let wallet = item as? Wallet else {return false}
                    return wallet.isHidden
                }
            )
        }
        
        override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
            let view = super.configureHeader(indexPath: indexPath) as? HeaderView
            view?.showHideHiddenWalletsAction = showHideHiddenWalletsAction
            return view
        }
        
        override func mapDataToCollectionViewItems() -> [BECollectionViewItem] {
            let viewModel = self.viewModel as? WalletsListViewModelType
            if viewModel?.isHiddenWalletsShown.value == true {
                return super.mapDataToCollectionViewItems()
            } else {
                return []
            }
        }
        
        override func dataDidLoad() {
            super.dataDidLoad()
            let viewModel = self.viewModel as! WalletsListViewModelType
            if let headerView = self.headerView() as? HeaderView {
                if viewModel.isHiddenWalletsShown.value {
                    headerView.imageView.tintColor = .textBlack
                    headerView.imageView.image = .visibilityHide
                    headerView.headerLabel.textColor = .textBlack
                    headerView.headerLabel.text = L10n.hide
                } else {
                    headerView.imageView.tintColor = .textSecondary
                    headerView.imageView.image = .visibilityShow
                    headerView.headerLabel.textColor = .textSecondary
                    headerView.headerLabel.text = L10n.dHiddenWallet(viewModel.hiddenWallets().count)
                }
                if viewModel.hiddenWallets().isEmpty {
                    headerView.removeStackView { [weak self] in
                        self?.collectionViewLayout?.invalidateLayout()
                    }
                } else {
                    headerView.addStackView { [weak self] in
                        self?.collectionViewLayout?.invalidateLayout()
                    }
                }
            }
        }
    }
}

