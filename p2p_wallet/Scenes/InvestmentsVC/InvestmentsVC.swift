//
//  InvestmentsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation
import DiffableDataSources

class InvestmentsVC: CollectionVC<InvestmentsVC.ItemType, NewsCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    enum ItemType: Hashable, Equatable {
        case news(News)
        case defi(String)
    }
    
    init() {
        let viewModel = InvestmentsVM()
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
    }
    
    override func registerCellAndSupplementaryViews() {
        super.registerCellAndSupplementaryViews()
        collectionView.registerCells([DefiCell.self])
    }
    
    // MARK: - Binding
    override func mapDataToSnapshot() -> DiffableDataSourceSnapshot<String, ItemType> {
        // initial snapshot
        var snapshot = DiffableDataSourceSnapshot<String, ItemType>()
        let section = L10n.makeYourCryptoWorkingOnYou
        snapshot.appendSections([section])
        snapshot.appendItems(
            [
                ItemType.news(
                    News(title: "How it works", subtitle: "The most important info you should know before investing", imageUrl: nil)
                ),
                ItemType.news(
                    News(title: "How it works2", subtitle: "The most important info you should know before investing2", imageUrl: nil)
                ),
                ItemType.news(
                    News(title: "How it works2", subtitle: "The most important info you should know before investing2", imageUrl: nil)
                )
            ],
            toSection: section
        )
        
        let section2 = L10n.exploreDeFi
        snapshot.appendSections([section2])
        snapshot.appendItems(
            [
                ItemType.defi("Test1"),
                ItemType.defi("Test2"),
                ItemType.defi("Test3")
            ],
            toSection: section2
        )
        return snapshot
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(headerTitle: L10n.makeYourCryptoWorkingOnYou, headerFont: .systemFont(ofSize: 28, weight: .semibold), interGroupSpacing: 16, orthogonalScrollingBehavior: .groupPaging),
            Section(headerTitle: L10n.exploreDeFi, interGroupSpacing: 2)
        ]
    }
    
    override func createLayoutForGroupOnSmallScreen(sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        if sectionIndex == 0 {
            let width = env.container.contentSize.width - 32 - 16
            return groupLayoutForFirstSection(width: width, height: width * 259 / 335)
        }
        return super.createLayoutForGroupOnSmallScreen(sectionIndex: sectionIndex, env: env)
    }
    
    override func createLayoutForGroupOnLargeScreen(sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        if sectionIndex == 0 {
            return groupLayoutForFirstSection(width: 335, height: 259)
        }
        return super.createLayoutForGroupOnLargeScreen(sectionIndex: sectionIndex, env: env)
    }
    
    private func groupLayoutForFirstSection(width: CGFloat, height: CGFloat) -> NSCollectionLayoutGroup {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(height))
        return NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    }
    
    // MARK: - Datasource
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell {
        switch item {
        case .news(let news):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: NewsCell.self), for: indexPath) as! NewsCell
            cell.setUp(with: news)
            return cell
        case .defi(let string):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: DefiCell.self), for: indexPath) as! DefiCell
            cell.setUp(with: string)
            return cell
        }
    }
}
