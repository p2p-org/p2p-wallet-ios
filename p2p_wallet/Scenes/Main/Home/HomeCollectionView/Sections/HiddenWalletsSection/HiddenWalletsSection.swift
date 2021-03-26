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
    class HiddenWalletsSection: BaseHiddenWalletsSection {
        init(index: Int, viewModel: WalletsListViewModelType) {
            super.init(
                index: index,
                viewModel: viewModel,
                header: .init(
                    identifier: "HiddenWalletsSectionHeaderView",
                    viewClass: HeaderView.self
                ),
                customFilter: { item in
                    guard let wallet = item as? Wallet else {return false}
                    return wallet.isHidden
                }
            )
        }
    }
}
