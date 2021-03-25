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
    private let hiddenWalletsSection: HiddenWalletsSection
    private let friendSection: FriendsSection
    
    // MARK: - Actions
    var openProfileAction: CocoaAction? {
        didSet {
            self.activeWalletsSection.openProfileAction = openProfileAction
        }
    }
    var receiveAction: CocoaAction? {
        didSet {
            friendSection.receiveAction = receiveAction
        }
    }
    var sendAction: CocoaAction? {
        didSet {
            friendSection.sendAction = sendAction
        }
    }
    var swapAction: CocoaAction? {
        didSet {
            friendSection.swapAction = swapAction
        }
    }
    var showAllProductsAction: CocoaAction? {
        didSet {
            self.hiddenWalletsSection.showAllProductsAction = showAllProductsAction
        }
    }
    
    var walletCellEditAction: Action<Wallet, Void>?
    
    // MARK: - Initializers
    init(viewModel: WalletsListViewModelType) {
        self.viewModel = viewModel
        self.activeWalletsSection = ActiveWalletsSection(index: 0, viewModel: viewModel)
        self.hiddenWalletsSection = HiddenWalletsSection(index: 1, viewModel: viewModel)
        self.friendSection = FriendsSection(index: 2, viewModel: FriendsViewModel())
        
        super.init(sections: [
            activeWalletsSection,
            hiddenWalletsSection,
            friendSection
        ])
    }
}
