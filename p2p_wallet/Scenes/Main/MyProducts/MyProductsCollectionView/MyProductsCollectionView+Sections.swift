//
//  MyProductsCollectionView+Sections.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/03/2021.
//

import Foundation
import BECollectionView
import Action

extension MyProductsCollectionView {
    class ActiveWalletSection: WalletsSection {
        init(index: Int, viewModel: WalletsListViewModelType) {
            super.init(
                index: index,
                layout: .init(
                    header: .init(
                        viewClass: FirstSectionHeaderView.self
                    ),
                    cellType: HomeWalletCell.self,
                    interGroupSpacing: 30,
                    itemHeight: .estimated(45),
                    contentInsets: NSDirectionalEdgeInsets(top: 0, leading: .defaultPadding, bottom: .defaultPadding, trailing: .defaultPadding),
                    horizontalInterItemSpacing: .fixed(16)
                ),
                viewModel: viewModel,
                customFilter: { item in
                    guard let wallet = item as? Wallet else {return false}
                    return !wallet.isHidden
                }
            )
        }
        
        override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
            let headerView = super.configureHeader(indexPath: indexPath) as? FirstSectionHeaderView
            headerView?.balancesOverviewView.setUp(state: viewModel.currentState, data: viewModel.getData(type: Wallet.self))
            return headerView
        }
        
        override func dataDidLoad() {
            super.dataDidLoad()
            let view = headerView() as? FirstSectionHeaderView
            view?.balancesOverviewView.setUp(state: viewModel.currentState, data: viewModel.getData(type: Wallet.self))
        }
    }
    
    class HiddenWalletSection: BaseHiddenWalletsSection {
        init(index: Int, viewModel: WalletsListViewModelType) {
            super.init(
                index: index,
                layout: .init(
                    header: .init(
                        viewClass: HiddenWalletsSectionHeaderView.self
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
    }
}
