//
//  WalletsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/03/2021.
//

import Foundation
import BECollectionView
import Action
import RxSwift

class WalletsCollectionView: BECollectionView {
    let walletsRepository: WalletsRepository
    let activeWalletsSection: WalletsSection
    let hiddenWalletsSection: HiddenWalletsSection
    
    var showHideHiddenWalletsAction: CocoaAction? {
        didSet {
            hiddenWalletsSection.showHideHiddenWalletsAction = showHideHiddenWalletsAction
        }
    }
    
    var walletCellEditAction: Action<Wallet, Void>? {
        didSet {
            activeWalletsSection.walletCellEditAction = walletCellEditAction
            hiddenWalletsSection.walletCellEditAction = walletCellEditAction
        }
    }
    
    init(
        walletsRepository: WalletsRepository,
        activeWalletsSection: WalletsSection,
        hiddenWalletsSection: HiddenWalletsSection,
        additionalSections: [BECollectionViewSection] = []
    ) {
        self.walletsRepository = walletsRepository
        self.activeWalletsSection = activeWalletsSection
        self.hiddenWalletsSection = hiddenWalletsSection
        super.init(sections: [
            activeWalletsSection,
            hiddenWalletsSection
        ] + additionalSections)
    }
    
    override func dataDidChangeObservable() -> Observable<Void> {
        walletsRepository.dataDidChange
    }
}
