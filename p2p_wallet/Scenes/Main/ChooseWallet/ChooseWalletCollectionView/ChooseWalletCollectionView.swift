//
//  ChooseWalletCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import BECollectionView

class ChooseWalletCollectionView: BECollectionView {
    // MARK: - Properties
    let viewModel: ChooseWalletViewModel
    
    // MARK: - Initializers
    init(viewModel: ChooseWalletViewModel, firstSectionFilter: ((AnyHashable) -> Bool)? = nil) {
        self.viewModel = viewModel
        
        var sections: [BECollectionViewSection] = [ FirstSection(viewModel: viewModel, filter: firstSectionFilter) ]
        
        if let viewModel = viewModel.otherWalletsViewModel {
            sections.append(
                SecondSection(viewModel: viewModel, firstSectionFilter: firstSectionFilter)
            )
        }
        
        super.init(sections: sections)
    }
    
    override func refreshAllSections() {
        sections.first?.reload()
    }
    
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<AnyHashable, BECollectionViewItem> {
        // get snapshot to modify
        var snapshot = super.mapDataToSnapshot()
        
        // if firstSection isEmpty but secondSection is not, then remove EmptyCell
        if snapshot.sectionIdentifiers.contains(0) &&
            snapshot.sectionIdentifiers.contains(1)
        {
            if snapshot.isSectionEmpty(sectionIdentifier: 0) &&
                !snapshot.isSectionEmpty(sectionIdentifier: 1)
            {
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: 0))
            }
        }
        
        return snapshot
    }
    
    override func didEndDecelerating() {
        super.didEndDecelerating()
        // get indexPaths
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        // get sections
        let visibleWallets = visibleIndexPaths.map {dataSource.itemIdentifier(for: $0)}.compactMap {$0?.value as? Wallet}
        viewModel.pricesRepository.fetchCurrentPrices(coins: visibleWallets.map {$0.token.symbol})
    }
}
