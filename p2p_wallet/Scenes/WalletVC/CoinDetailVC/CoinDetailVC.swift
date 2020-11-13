//
//  CoinDetailVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import DiffableDataSources

class CoinDetailVC: CollectionVC<SolanaSDK.Token, TokenCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .normal()
    }
    
    override var sections: [Section] {
        [Section(headerViewClass: CoinDetailSectionHeaderView.self, headerTitle: L10n.activities)]
    }
    
    // MARK: - Initializer
    init() {
        super.init(viewModel: ListViewModel<SolanaSDK.Token>())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        title = "Coin name"
    }
    
    // MARK: - Binding
    override func mapDataToSnapshot() -> DiffableDataSourceSnapshot<String, SolanaSDK.Token> {
        var snapshot = DiffableDataSourceSnapshot<String, SolanaSDK.Token>()
        let section = L10n.activities
        snapshot.appendSections([section])
        return snapshot
    }
    
    override func createLayoutForSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let section = super.createLayoutForSection(sectionIndex, environment: env)
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section?.boundarySupplementaryItems = [sectionHeader]
        return section
    }
}
