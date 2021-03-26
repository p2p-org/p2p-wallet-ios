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

class MyProductsCollectionView: BECollectionView {
    private let walletsViewModel: WalletsListViewModelType
    private let activeWalletsSection: ActiveWalletSection
    private let hiddenWalletsSection: HiddenWalletSection
    
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
    
    init(walletsViewModel: WalletsListViewModelType) {
        self.walletsViewModel = walletsViewModel
        activeWalletsSection = ActiveWalletSection(index: 0, viewModel: walletsViewModel)
        hiddenWalletsSection = HiddenWalletSection(index: 1, viewModel: walletsViewModel)
        super.init(sections: [
            activeWalletsSection,
            hiddenWalletsSection
        ])
    }
    
    override func dataDidChangeObservable() -> Observable<Void> {
        walletsViewModel.dataDidChange
    }
}
