//
//  NewsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import BECollectionView
import Foundation

class NewsSection: BEStaticSectionsCollectionView.Section {
    init(index: Int, viewModel: NewsViewModel) {
        super.init(
            index: index,
            layout: .init(
                header: .init(
                    viewClass: SectionHeaderView.self
                ),
                cellType: NewsCell.self,
                interGroupSpacing: 16,
                orthogonalScrollingBehavior: .groupPaging,
                customLayoutForGroupOnSmallScreen: { env in
                    let width = env.container.contentSize.width - 32 - 16
                    return groupLayoutForFirstSection(width: width, height: width * 259 / 335)
                },
                customLayoutForGroupOnLargeScreen: { _ in
                    groupLayoutForFirstSection(width: 335, height: 259)
                }
            ),
            viewModel: viewModel
        )
    }

    override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
        let header = super.configureHeader(indexPath: indexPath) as? SectionHeaderView
        header?.setUp(
            headerTitle: L10n.makeYourCryptoWorkingOnYou,
            headerFont: .systemFont(ofSize: 28, weight: .semibold)
        )
        return header
    }
}

private func groupLayoutForFirstSection(width: CGFloat, height: CGFloat) -> NSCollectionLayoutGroup {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(height))
    return NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
}
