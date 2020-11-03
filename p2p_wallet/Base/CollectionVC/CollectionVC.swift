//
//  CollectionVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation
import IBPCollectionViewCompositionalLayout
import DiffableDataSources

class CollectionCell<ItemType: Hashable>: BaseCollectionViewCell {
    func setUp(with item: ItemType) {}
}

class CollectionVC<Section: Hashable, ItemType: Hashable, Cell: CollectionCell<ItemType>>: BaseVC {
    enum State {
        case reloading
        case loading
        case loaded([ItemType])
    }
    
    var dataSource: CollectionViewDiffableDataSource<Section, ItemType>!
    
    lazy var collectionView: BaseCollectionView = {
        let collectionView = BaseCollectionView(frame: .zero, collectionViewLayout: createLayout())
        return collectionView
    }()
    
    override func setUp() {
        super.setUp()
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(all: 16))
        
        registerCellAndSupplementaryViews()
        configureDataSource()
    }
    
    func registerCellAndSupplementaryViews() {
        collectionView.registerCells([Cell.self])
    }
    
    // MARK: - Layout
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { (sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            self.configureSection(sectionIndex, environment: env)
        }
    }
    
    func configureSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
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
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [sectionHeader]
        
        return section
    }
    
    // MARK: - Datasource
    private func configureDataSource() {
        dataSource = CollectionViewDiffableDataSource<Section, ItemType>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell? in
            self.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }
                
        dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            self.configureSupplementaryView(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
    }
    
    func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: Cell.self), for: indexPath) as! CollectionCell<ItemType>
        cell.setUp(with: item)
        return cell
    }
    
    func configureSupplementaryView(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
    }
}
