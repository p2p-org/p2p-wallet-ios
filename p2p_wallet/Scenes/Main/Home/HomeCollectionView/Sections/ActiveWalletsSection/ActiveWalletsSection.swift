//
//  ActiveWalletsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import BECollectionView
import Action

class ActiveWalletsSection: HomeWalletsSection {
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
                horizontalInterItemSpacing: .fixed(16)
            ),
            viewModel: viewModel,
            customFilter: { item in
                guard let wallet = item as? Wallet else {return false}
                return !wallet.isHidden
            }
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
