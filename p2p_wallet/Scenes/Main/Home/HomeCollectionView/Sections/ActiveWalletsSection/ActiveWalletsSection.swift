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
        var openProfileAction: CocoaAction?
        
        init(index: Int, viewModel: WalletsRepository) {
            super.init(
                index: index,
                viewModel: viewModel,
                header: .init(
                    identifier: "ActiveWalletsSectionHeaderView",
                    viewClass: HeaderView.self
                ),
                background: BackgroundView.self,
                cellType: HomeWalletCell.self,
                limit: 4
            )
        }
        
        override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
            let view = super.configureHeader(indexPath: indexPath) as? HeaderView
            view?.openProfileAction = openProfileAction
            return view
        }
    }
}
