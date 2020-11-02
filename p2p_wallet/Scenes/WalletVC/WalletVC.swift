//
//  WalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import IBPCollectionViewCompositionalLayout
import DiffableDataSources

class WalletVC: BaseVC, UICollectionViewDelegate {
    typealias ItemType = String
    
    enum Section: String, CaseIterable {
        case wallets
        case savings
        
        var rawValue: String {
            switch self {
            case .wallets:
                return L10n.wallets
            case .savings:
                return L10n.savings
            }
        }
    }
    
    var dataSource: CollectionViewDiffableDataSource<Section, ItemType>!
    
    lazy var collectionView = WalletCollectionView()
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        configureDataSource()
        
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
        
        collectionView.delegate = self
        
        var snapshot = DiffableDataSourceSnapshot<Section, ItemType>()
        var items = [String]()
        for i in 0..<100 {
            items.append("\(i)")
        }
        let section = Section.wallets
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
        
        dataSource.apply(snapshot)
    }
    
    func configureDataSource() {
        dataSource = CollectionViewDiffableDataSource<Section, String>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PriceCell", for: indexPath) as! PriceCell
            cell.coinNameLabel.text = item
            return cell
        }
        
        
        dataSource.supplementaryViewProvider = { (
            collectionView: UICollectionView,
            kind: String,
            indexPath: IndexPath) -> UICollectionReusableView? in
            
            if indexPath.section == 0 {
                let view = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: "WCVFirstSectionHeaderView",
                    for: indexPath) as? WCVFirstSectionHeaderView
                return view
            }
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "WCVFirstSectionHeaderView",
                for: indexPath) as? WCVFirstSectionHeaderView
            return view
        }
    }
}
