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
        
        var localizedString: String {
            switch self {
            case .wallets:
                return L10n.wallets
            case .savings:
                return L10n.savings
            }
        }
    }
    
    var dataSource: CollectionViewDiffableDataSource<Section, ItemType>!
    lazy var qrStackView: UIStackView = {
        let stackView = UIStackView(axis: .horizontal, spacing: 25, alignment: .center, distribution: .fill)
        stackView.addArrangedSubview(
            UIImageView(
                width: 25,
                height: 25,
                backgroundColor: UIColor.textBlack.withAlphaComponent(0.5),
                image: .scanQr
            )
        )
        stackView.addArrangedSubview(
            UILabel(
                text: L10n.slideToScan,
                textSize: 13,
                weight: .semibold,
                textColor: UIColor.textBlack.withAlphaComponent(0.5)
            )
        )
        stackView.addArrangedSubview(.spacer)
        return stackView
    }()
    lazy var collectionView = WalletCollectionView()
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        configureDataSource()
        
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        
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
                
        dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            
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
