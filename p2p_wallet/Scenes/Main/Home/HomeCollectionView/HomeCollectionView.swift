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
    let viewModel: WalletsListViewModelType
    
    // MARK: - Sections
    private let activeWalletsSection: ActiveWalletsSection
    private let hiddenWalletsSection: HiddenWalletsSection
    private let friendSection: FriendsSection
    
    // MARK: - Actions
    var showHideHiddenWalletsAction = CocoaAction { [weak self] in
        self?.viewModel.walletsVM.toggleIsHiddenWalletShown()
        return .just(())
    }
    
    var walletCellEditAction: Action<Wallet, Void>? {
        didSet {
            
        }
    }
    
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
