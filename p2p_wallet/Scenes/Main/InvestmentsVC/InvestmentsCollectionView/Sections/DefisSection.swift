//
//  DefisSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import BECollectionView
import Foundation

class DefisSection: BEStaticSectionsCollectionView.Section {
    init(index: Int, viewModel: DefisViewModel) {
        super.init(
            index: index,
            layout: .init(
                header: .init(
                    viewClass: SectionHeaderView.self
                ),
                cellType: DefiCell.self,
                interGroupSpacing: 2
            ),
            viewModel: viewModel
        )
    }

    override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
        let header = super.configureHeader(indexPath: indexPath) as? SectionHeaderView
        header?.setUp(headerTitle: L10n.exploreDeFi)
        return header
    }
}
