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
    let viewModel: WalletsListViewModelType
    
    // MARK: - Sections
    private let activeWalletsSection: ActiveWalletsSection
    
    // MARK: - Actions
    var openProfileAction: CocoaAction? {
        didSet {
            self.activeWalletsSection.openProfileAction = openProfileAction
        }
    }
    var receiveAction: CocoaAction?
    var sendAction: CocoaAction?
    var swapAction: CocoaAction?
    var showAllProductsAction: CocoaAction?
    
    var walletCellEditAction: Action<Wallet, Void>?
    
    // MARK: - Initializers
    init(viewModel: WalletsListViewModelType) {
        self.viewModel = viewModel
        self.activeWalletsSection = ActiveWalletsSection(index: 0, viewModel: viewModel)
        super.init(sections: [
            activeWalletsSection,
            HiddenWalletsSection(index: 1, viewModel: viewModel),
            FriendsSection(index: 2, viewModel: FriendsViewModel())
        ])
    }
}
