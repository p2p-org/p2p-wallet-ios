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
                viewModel: viewModel,
                header: .init(
                    viewClass: FirstSectionHeaderView.self
                )
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
}
