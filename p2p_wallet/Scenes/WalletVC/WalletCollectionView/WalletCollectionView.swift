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
        UICollectionViewCompositionalLayout { (_ : Int, _ : NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
}
