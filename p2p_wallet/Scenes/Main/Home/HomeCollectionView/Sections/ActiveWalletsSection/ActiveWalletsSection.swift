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
    var openProfileAction: CocoaAction?
    
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
}
