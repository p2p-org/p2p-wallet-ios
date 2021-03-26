//
//  MyProductsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation
import Action
import BECollectionView
import RxSwift

class MyProductsCollectionView: WalletsCollectionView {
    init(walletsViewModel: WalletsListViewModelType) {
        super.init(
            walletsViewModel: walletsViewModel,
            activeWalletsSection: ActiveWalletSection(index: 0, viewModel: walletsViewModel),
            hiddenWalletsSection: HiddenWalletsSection(index: 1, viewModel: walletsViewModel, limit: 4)
        )
    }
}
