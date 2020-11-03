//
//  WalletCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import IBPCollectionViewCompositionalLayout

class WalletCollectionView: BaseCollectionView {
    static let sectionHeaderElementKind = "section-header-element-kind"
    
    init() {
        super.init(frame: .zero, collectionViewLayout: WalletCollectionView.layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func commonInit() {
        super.commonInit()
        configureForAutoLayout()
        register(WCVSectionHeaderView.self, forSupplementaryViewOfKind: WalletCollectionView.sectionHeaderElementKind, withReuseIdentifier: "WCVSectionHeaderView")
        register(WCVFirstSectionHeaderView.self, forSupplementaryViewOfKind: WalletCollectionView.sectionHeaderElementKind, withReuseIdentifier: "WCVFirstSectionHeaderView")
        // register cells
        registerCells([PriceCell.self])
    }
    
    static var layout: UICollectionViewLayout {
        UICollectionViewCompositionalLayout { (_ : Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            // 1 columns
            let group: NSCollectionLayoutGroup
            
            if env.container.contentSize.width < 536 {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200))
                
                group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            } else {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(100))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1))
                
                let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                leadingGroup.interItemSpacing = .fixed(16)
                
                let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                trailingGroup.interItemSpacing = .fixed(16)
                
                let combinedGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200))
                group = NSCollectionLayoutGroup.horizontal(layoutSize: combinedGroupSize, subitems: [item])
            }
            
            group.interItemSpacing = .fixed(16)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
            
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: WalletCollectionView.sectionHeaderElementKind,
                alignment: .top
            )
            section.boundarySupplementaryItems = [sectionHeader]
            
            return section
        }
    }
}
