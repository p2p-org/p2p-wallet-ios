//
//  WalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import IBPCollectionViewCompositionalLayout
import DiffableDataSources

class WalletVC: BaseVC, TabBarItemVC, UICollectionViewDelegate {
    // MARK: - Nested type
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
    
    // MARK: - Properties
    var dataSource: CollectionViewDiffableDataSource<Section, ItemType>!
    
    // MARK: - Subviews
    lazy var qrStackView: UIStackView = {
        let stackView = UIStackView(axis: .horizontal, spacing: 25, alignment: .center, distribution: .fill)
        let imageView = UIImageView(width: 25, height: 25, image: .scanQr)
        imageView.tintColor = UIColor.textBlack.withAlphaComponent(0.5)
         
        stackView.addArrangedSubviews([
            imageView,
            UILabel(text: L10n.slideToScan, textSize: 13, weight: .semibold, textColor: UIColor.textBlack.withAlphaComponent(0.5))
        ])
        stackView.addArrangedSubview(.spacer)
        return stackView
    }()
    lazy var collectionView = WalletCollectionView()
    var scrollView: UIScrollView {collectionView}
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        configureDataSource()
        
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        
        collectionView.delegate = self
        
        var snapshot = DiffableDataSourceSnapshot<Section, ItemType>()
        var items = [String]()
        for i in 0..<5 {
            items.append("\(i)")
        }
        let section = Section.wallets
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
        
        let section2 = Section.savings
        snapshot.appendSections([section2])
        items = []
        for i in 6..<10 {
            items.append("\(i)")
        }
        snapshot.appendItems(items, toSection: section2)
        
        dataSource.apply(snapshot)
    }
    
    // MARK: - Helpers
    private func configureDataSource() {
        dataSource = CollectionViewDiffableDataSource<Section, String>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PriceCell", for: indexPath) as! PriceCell
//            cell.coinNameLabel.text = item
            return cell
        }
                
        dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            
            if indexPath.section == 0 {
                let view = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: "WCVFirstSectionHeaderView",
                    for: indexPath) as? WCVFirstSectionHeaderView
                view?.headerLabel.text = Section.wallets.localizedString
                return view
            }
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "WCVSectionHeaderView",
                for: indexPath) as? WCVSectionHeaderView
            view?.headerLabel.text = Section.savings.localizedString
            return view
        }
    }
}
