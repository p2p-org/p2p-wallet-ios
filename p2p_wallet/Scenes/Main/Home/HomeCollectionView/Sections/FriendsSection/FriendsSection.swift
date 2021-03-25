//
//  FriendsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import BECollectionView

class FriendsSection: BECollectionViewSection {
    init(index: Int, viewModel: FriendsViewModel) {
        super.init(
            index: index,
            layout: .init(
                header: .init(
                    identifier: "FriendsSectionHeaderView",
                    viewClass: HeaderView.self
                ),
                cellType: HomeFriendCell.self,
                interGroupSpacing: 16,
                contentInsets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
                horizontalInterItemSpacing: .fixed(16),
                background: FriendsSectionBackgroundView.self, customLayoutForGroupOnSmallScreen: {_ in
                    Self.groupLayoutForFriendSection()
                },
                customLayoutForGroupOnLargeScreen: {_ in
                    Self.groupLayoutForFriendSection()
                }
            ),
            viewModel: viewModel
        )
    }
    
    private static func groupLayoutForFriendSection() -> NSCollectionLayoutGroup {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(80), heightDimension: .estimated(73))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(16)
        return group
    }
}
