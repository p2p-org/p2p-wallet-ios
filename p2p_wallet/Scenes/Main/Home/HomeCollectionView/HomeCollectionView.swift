//
//  HomeCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import Action
import BECollectionView
import RxSwift

class HomeCollectionView: WalletsCollectionView {
    // MARK: - Constants
    let viewModel: WalletsListViewModelType
    
    // MARK: - Sections
    private let friendSection: FriendsSection
    
    // MARK: - Actions
    // MARK: - Initializers
    init(viewModel: WalletsListViewModelType) {
        self.viewModel = viewModel
        self.friendSection = FriendsSection(index: 2, viewModel: FriendsViewModel())
        super.init(
            walletsViewModel: viewModel,
            activeWalletsSection: ActiveWalletsSection(index: 0, viewModel: viewModel),
            hiddenWalletsSection: HiddenWalletsSection(index: 1, viewModel: viewModel),
            additionalSections: [/*friendSection*/]
        )
    }
}
