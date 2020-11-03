//
//  WalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import DiffableDataSources

class WalletVC: CollectionVC<WalletVC.Section, String, PriceCell> {
    // MARK: - Nested type
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
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        
        // modify collectionView
        collectionView.contentInset = collectionView.contentInset.modifying(dTop: 10+25+10)
        
        // header view
        let headerView = UIView(backgroundColor: view.backgroundColor)
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        headerView.addSubview(qrStackView)
        qrStackView.autoPinToTopLeftCornerOfSuperviewSafeArea(xInset: 16, yInset: 10)
        qrStackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
        
        // initial snapshot
        var snapshot = DiffableDataSourceSnapshot<Section, String>()
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
    
    override func registerCellAndSupplementaryViews() {
        super.registerCellAndSupplementaryViews()
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderView")
        collectionView.register(WCVFirstSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "WCVFirstSectionHeaderView")
    }
    
    override func createLayoutForSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let group: NSCollectionLayoutGroup
        // 1 columns
        if env.container.contentSize.width < 536 {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200))
            
            group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        // 2 columns
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
        
        // Header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
        
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [sectionHeader]
        return section
    }
    
    override func configureSupplementaryView(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
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
            withReuseIdentifier: "SectionHeaderView",
            for: indexPath) as? SectionHeaderView
        view?.headerLabel.text = Section.savings.localizedString
        return view

    }
}

extension WalletVC: TabBarItemVC {
    var scrollView: UIScrollView {collectionView}
}
