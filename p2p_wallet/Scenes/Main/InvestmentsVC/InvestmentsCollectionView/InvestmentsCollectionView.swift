//
//  InvestmentsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import Foundation
import BECollectionView

class InvestmentsCollectionView: BECollectionView {
    // MARK: - Properties
    let newsSection: NewsSection
    let defisSection: BECollectionViewSection
    
    // MARK: - Initializers
    init(
        newsViewModel: NewsViewModel,
        defisViewModel: DefisViewModel
    ) {
        newsSection = NewsSection(
            index: 0,
            viewModel: newsViewModel
        )
        
        defisSection = DefisSection(
            index: 1,
            viewModel: defisViewModel
        )
        
        super.init(sections: [
            newsSection,
            defisSection
        ])
    }
}
