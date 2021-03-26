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
    let numberOfWalletsToShow = 4
    let viewModel: WalletsListViewModelType
    
    // MARK: - Sections
    private let friendSection: FriendsSection
    
    // MARK: - Actions
    var openProfileAction: CocoaAction? {
        didSet {
            (self.activeWalletsSection as! ActiveWalletsSection).openProfileAction = openProfileAction
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
            (self.hiddenWalletsSection as! HomeHiddenWalletsSection).showAllProductsAction = showAllProductsAction
        }
    }
    
    // MARK: - Initializers
    init(viewModel: WalletsListViewModelType) {
        self.viewModel = viewModel
        self.friendSection = FriendsSection(index: 2, viewModel: FriendsViewModel())
        super.init(
            walletsViewModel: viewModel,
            activeWalletsSection: ActiveWalletsSection(index: 0, viewModel: viewModel),
            hiddenWalletsSection: HomeHiddenWalletsSection(index: 1, viewModel: viewModel),
            additionalSections: [friendSection]
        )
    }
}
