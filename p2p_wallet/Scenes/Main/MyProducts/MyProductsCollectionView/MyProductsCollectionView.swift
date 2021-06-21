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
    init(repository: WalletsRepository) {
        super.init(
            walletsRepository: repository,
            activeWalletsSection: ActiveWalletSection(index: 0, viewModel: repository),
            hiddenWalletsSection: HiddenWalletsSection(index: 1, viewModel: repository, limit: 4)
        )
    }
}
