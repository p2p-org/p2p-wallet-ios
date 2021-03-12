//
//  SwapDestinationWalletsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation

class ChooseWalletCollectionViewOtherCell: ChooseWalletCollectionViewCell {
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        addressLabel.text = item.symbol
        
        equityValueLabel.isHidden = true
        tokenCountLabel.isHidden = true
    }
}

class SwapDestinationWalletsCollectionView: ChooseWalletCollectionView {
    init(
        viewModel: WalletsVM,
        customFilter: @escaping ((Wallet) -> Bool)
    ) {
        super.init(viewModel: viewModel, sections: [
            CollectionViewSection(
                header: .init(title: L10n.yourTokens, titleFont: .systemFont(ofSize: 15)),
                cellType: ChooseWalletCollectionViewCell.self,
                interGroupSpacing: 16
            ),
            CollectionViewSection(
                header: .init(title: L10n.allTokens, titleFont: .systemFont(ofSize: 15)),
                cellType: ChooseWalletCollectionViewOtherCell.self,
                interGroupSpacing: 16
            )
        ], customFilter: customFilter)
    }
    
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, CollectionViewItem<Wallet>> {
        var snapshot = super.mapDataToSnapshot()
        let section2 = sections.last!.header!.title
        
        let allItems = viewModel.searchResult == nil ? filter(viewModel.items) : filter(viewModel.searchResult!)
        snapshot.appendSections([section2])
        let uncreatedItem = allItems.filter {$0.pubkey == nil}
            .map {CollectionViewItem(value: $0)}
        snapshot.appendItems(uncreatedItem, toSection: section2)
        return snapshot
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        if let header = headerForSection(0) as? SectionHeaderView {
            modifyHeaderFont(header)
        }
        
        if let header = headerForSection(1) as? SectionHeaderView {
            modifyHeaderFont(header)
        }
    }
    
    private func modifyHeaderFont(_ header: SectionHeaderView) {
        header.headerLabel.textColor = .textSecondary
    }
}
