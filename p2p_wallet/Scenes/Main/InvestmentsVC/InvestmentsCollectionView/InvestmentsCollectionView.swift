//
//  InvestmentsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import BECollectionView
import Foundation

class InvestmentsCollectionView: BEStaticSectionsCollectionView {
    // MARK: - Properties

    let newsSection: NewsSection
    let defisSection: DefisSection

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
            defisSection,
        ])
    }
}
