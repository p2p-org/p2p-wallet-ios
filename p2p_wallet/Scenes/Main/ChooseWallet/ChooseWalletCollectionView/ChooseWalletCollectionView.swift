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
        var snapshot = super.mapDataToSnapshot()
        
        let firstSectionCount = snapshot.numberOfItems(inSection: 0)
        
        if viewModel.otherWalletsViewModel != nil {
            let secondSectionCount = snapshot.numberOfItems(inSection: 1)
            
            if firstSectionCount == 1 && secondSectionCount > 0 {
                if let firstSectionItem = snapshot.itemIdentifiers(inSection: 0).first
                {
                    snapshot.deleteItems([firstSectionItem])
                }
            }
        }
        
        return snapshot
    }
}
