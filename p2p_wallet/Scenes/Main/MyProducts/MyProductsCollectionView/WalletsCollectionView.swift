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
    let walletsViewModel: WalletsListViewModelType
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
        walletsViewModel: WalletsListViewModelType,
        activeWalletsSection: WalletsSection,
        hiddenWalletsSection: HiddenWalletsSection,
        additionalSections: [BECollectionViewSection] = []
    ) {
        self.walletsViewModel = walletsViewModel
        self.activeWalletsSection = activeWalletsSection
        self.hiddenWalletsSection = hiddenWalletsSection
        super.init(sections: [
            activeWalletsSection,
            hiddenWalletsSection
        ] + additionalSections)
    }
    
    override func dataDidChangeObservable() -> Observable<Void> {
        walletsViewModel.dataDidChange
    }
}
