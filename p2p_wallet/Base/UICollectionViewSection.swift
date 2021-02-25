//
//  UICollectionViewSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation

struct CollectionViewSection {
    struct Header {
        var viewClass: SectionHeaderView.Type = SectionHeaderView.self
        var title: String
        var titleFont: UIFont = .systemFont(ofSize: 17, weight: .semibold)
        var layout: NSCollectionLayoutBoundarySupplementaryItem = {
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
            return NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
        }()
    }
    
    struct Footer {
        var viewClass: SectionFooterView.Type = SectionFooterView.self
        var layout: NSCollectionLayoutBoundarySupplementaryItem = {
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
            return NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: size,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
        }()
    }
    
    var header: Header?
    var footer: Footer?
    var cellType: BaseCollectionViewCell.Type
    var interGroupSpacing: CGFloat?
    var orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior?
    var itemHeight = NSCollectionLayoutDimension.estimated(100)
    var contentInsets = NSDirectionalEdgeInsets(top: 0, leading: .defaultPadding, bottom: 0, trailing: .defaultPadding)
    var horizontalInterItemSpacing = NSCollectionLayoutSpacing.fixed(16)
    var background: SectionBackgroundView.Type?
}
