//
//  HomeCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import Action
import BECollectionView

class HomeCollectionView: BECollectionView {
    // MARK: - Constants
    let numberOfWalletsToShow = 4
    
    // MARK: - Actions
    var openProfileAction: CocoaAction?
    var receiveAction: CocoaAction?
    var sendAction: CocoaAction?
    var swapAction: CocoaAction?
    var showAllProductsAction: CocoaAction?
    
    var walletCellEditAction: Action<Wallet, Void>?
    
    // MARK: - Initializers
    init(viewModel: WalletsListViewModelType) {
        super.init(sections: [
            ActiveWalletsSection(index: 0, viewModel: viewModel),
            HiddenWalletsSection(index: 1, viewModel: viewModel)
        ])
    }
}
