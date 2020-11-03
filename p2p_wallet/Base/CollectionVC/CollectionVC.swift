//
//  CollectionVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation
import IBPCollectionViewCompositionalLayout
import DiffableDataSources

protocol CollectionCell: BaseCollectionViewCell {
    associatedtype T: Hashable
    func setUp(with item: T)
}

class CollectionVC<Section: Hashable, ItemType: Hashable, Cell: CollectionCell>: BaseVC {
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
            self.createLayoutForSection(sectionIndex, environment: env)
        }
    }
    
    func createLayoutForSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let group: NSCollectionLayoutGroup
        // 1 columns
        if env.container.contentSize.width < 536 {
            group = createLayoutForGroupOnSmallScreen(sectionIndex: sectionIndex, env: env)
        // 2 columns
        } else {
            group = createLayoutForGroupOnLargeScreen(sectionIndex: sectionIndex, env: env)
        }
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        return section
    }
    
    func createLayoutForGroupOnSmallScreen(sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200))
        
        return NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
    }
    
    func createLayoutForGroupOnLargeScreen(sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        
        let leadingItem = NSCollectionLayoutItem(layoutSize: itemSize)
        leadingItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
        
        let trailingItem = NSCollectionLayoutItem(layoutSize: itemSize)
        trailingItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(300))
        
        let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [leadingItem])
        leadingGroup.interItemSpacing = .fixed(16)
        
        let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [trailingItem])
        trailingGroup.interItemSpacing = .fixed(16)
        
        let combinedGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200))
        return NSCollectionLayoutGroup.horizontal(layoutSize: combinedGroupSize, subitems: [leadingGroup, trailingGroup])
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: Cell.self), for: indexPath) as? Cell
        cell?.setUp(with: item as! Cell.T)
        return cell ?? UICollectionViewCell()
    }
    
    func configureSupplementaryView(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
    }
}
