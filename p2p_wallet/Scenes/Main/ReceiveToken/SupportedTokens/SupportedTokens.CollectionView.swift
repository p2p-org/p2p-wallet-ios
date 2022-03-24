//
//  SupportedTokens.CollectionView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.01.2022.
//

import BECollectionView
import SolanaSwift

extension SupportedTokens {
    class CollectionView: BEDynamicSectionsCollectionView {
        init(viewModel: SupportedTokensViewModelType) {
            super.init(
                header: .init(
                    viewType: TableHeaderView.self,
                    heightDimension: .estimated(162)
                ),
                viewModel: viewModel,
                mapDataToSections: { viewModel in
                    let tokens = viewModel.getData(type: SolanaSDK.Token.self)
                    let sections: [SectionInfo] = [
                        .init(userInfo: 0, items: tokens),
                    ]

                    return sections
                },
                layout: BECollectionViewSectionLayout(
                    cellType: Cell.self,
                    emptyCellType: WLEmptyCell.self,
                    interGroupSpacing: 8
                )
            )
        }

        override func configureCell(indexPath: IndexPath, item: BECollectionViewItem) -> UICollectionViewCell? {
            let cell = super.configureCell(indexPath: indexPath, item: item)

            if let cell = cell as? WLEmptyCell {
                cell.titleLabel.text = L10n.nothingFound
                cell.subtitleLabel.text = L10n.changeYourSearchPhrase
            }

            return cell
        }
    }
}
