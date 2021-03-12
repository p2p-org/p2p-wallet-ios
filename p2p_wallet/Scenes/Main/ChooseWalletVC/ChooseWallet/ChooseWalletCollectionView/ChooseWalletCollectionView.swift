//
//  ChooseWalletCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation

class ChooseWalletCollectionView: WalletsCollectionView {
    let customFilter: ((Wallet) -> Bool)
    init(
        viewModel: WalletsVM,
        sections: [CollectionViewSection] = [
            CollectionViewSection(
                header: CollectionViewSection.Header(title: ""),
                cellType: ChooseWalletCollectionViewCell.self,
                interGroupSpacing: 16
            )
        ],
        customFilter: @escaping ((Wallet) -> Bool)
    ) {
        self.customFilter = customFilter
        super.init(viewModel: viewModel, sections: sections)
    }
    
    override func filter(_ items: [Wallet]) -> [Wallet] {
        items.filter {customFilter($0)}
    }
    
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
        return snapshot
    }
}
