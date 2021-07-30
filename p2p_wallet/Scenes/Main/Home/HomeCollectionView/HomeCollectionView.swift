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
    
    // MARK: - Sections
    private let friendSection: FriendsSection
    
    // MARK: - Actions
    var openProfileAction: CocoaAction? {
        didSet {
            (self.activeWalletsSection as! ActiveWalletsSection).openProfileAction = openProfileAction
        }
    }
    var buyAction: CocoaAction? {
        didSet {
            friendSection.buyAction = buyAction
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
    init(walletsRepository: WalletsRepository) {
        self.friendSection = FriendsSection(index: 2, viewModel: FriendsViewModel())
        super.init(
            walletsRepository: walletsRepository,
            activeWalletsSection: ActiveWalletsSection(index: 0, viewModel: walletsRepository),
            hiddenWalletsSection: HomeHiddenWalletsSection(index: 1, viewModel: walletsRepository),
            additionalSections: [friendSection]
        )
    }
}
