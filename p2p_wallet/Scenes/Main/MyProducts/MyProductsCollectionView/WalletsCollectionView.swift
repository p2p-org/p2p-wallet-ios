//
//  WalletsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation
import Action

class WalletsCollectionView: CollectionView<Wallet, WalletsVM> {
    var walletCellEditAction: Action<Wallet, Void>?
    
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, CollectionViewItem<Wallet>> {
        // initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<String, CollectionViewItem<Wallet>>()
        
        // activeWallet
        let activeWalletSections = L10n.wallets
        snapshot.appendSections([activeWalletSections])
        
        var items = viewModel.shownWallets()
            .map {CollectionViewItem(value: $0)}
        switch viewModel.state.value {
        case .loading:
            items += [
                CollectionViewItem(placeholderIndex: 0),
                CollectionViewItem(placeholderIndex: 1)
            ]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: activeWalletSections)
        
        // hiddenWallet
        let hiddenWalletSections = sections[1].header?.title ?? "Hidden"
        var hiddenItems = [CollectionViewItem<Wallet>]()
//        if viewModel.isHiddenWalletsShown.value {
            hiddenItems = viewModel.hiddenWallets()
                .map {CollectionViewItem(value: $0)}
//        }
        snapshot.appendSections([hiddenWalletSections])
        snapshot.appendItems(hiddenItems, toSection: hiddenWalletSections)
        return snapshot
    }
    
    override func setUpCell(cell: UICollectionViewCell, withItem wallet: Wallet?) {
        super.setUpCell(cell: cell, withItem: wallet)
        (cell as? EditableWalletCell)?.editAction = CocoaAction { [unowned self] in
            if let wallet = wallet {
                self.walletCellEditAction?.execute(wallet)
            }
            return .just(())
        }
        (cell as? EditableWalletCell)?.hideAction = CocoaAction { [unowned self] in
            if let wallet = wallet {
                if wallet.isHidden {
                    self.viewModel.unhideWallet(wallet)
                } else {
                    self.viewModel.hideWallet(wallet)
                }
            }
            return .just(())
        }
    }
}
