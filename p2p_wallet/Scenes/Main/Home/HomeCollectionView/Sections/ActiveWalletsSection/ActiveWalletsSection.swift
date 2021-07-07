//
//  ActiveWalletsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import BECollectionView
import Action

extension HomeCollectionView {
    class ActiveWalletsSection: WalletsSection {
        init(index: Int, viewModel: WalletsRepository) {
            super.init(
                index: index,
                viewModel: viewModel,
                cellType: HomeWalletCell.self
            )
        }
        
    //    override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
    //        let viewModel = self.viewModel as! WalletsListViewModelType
    //        let headerView = super.configureHeader(indexPath: indexPath) as? HeaderView
    //        headerView?.balancesOverviewView.setUp(state: viewModel.currentState, data: viewModel.getData(type: Wallet.self))
    //        return headerView
    //    }
        
        override func dataDidLoad() {
            super.dataDidLoad()
            let view = headerView() as? HeaderView
            view?.balancesOverviewView.setUp(state: viewModel.currentState, data: viewModel.getData(type: Wallet.self))
        }
    }
}
