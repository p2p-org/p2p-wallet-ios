//
//  CollectionVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation
import IBPCollectionViewCompositionalLayout
import DiffableDataSources
import RxSwift

protocol CollectionCell: BaseCollectionViewCell, LoadableView {
    associatedtype T: ListItemType
    func setUp(with item: T)
}

protocol ListItemType: Hashable {
    static func placeholder(at index: Int) -> Self
    var id: String {get}
}

extension ListItemType {
    static func placeholderId(at index: Int) -> String {
        "placeholder#\(index)"
    }
}

class CollectionVC<ItemType: ListItemType, Cell: CollectionCell>: BaseVC, UICollectionViewDelegate {
    // MARK: - Nested type
    struct Section {
        var headerViewClass: SectionHeaderView.Type = SectionHeaderView.self
        let headerTitle: String
        var headerFont: UIFont = .systemFont(ofSize: 17, weight: .semibold)
        var headerLayout: NSCollectionLayoutBoundarySupplementaryItem? = {
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
            return NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
        }()
        var footerViewClass: SectionFooterView.Type = SectionFooterView.self
        var footerLayout: NSCollectionLayoutBoundarySupplementaryItem? = {
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
            return NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: size,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
        }()
        var interGroupSpacing: CGFloat?
        var orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior?
        var itemHeight = NSCollectionLayoutDimension.estimated(100)
        var contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        var horizontalInterItemSpacing = NSCollectionLayoutSpacing.fixed(16)
    }
    
    // MARK: - Properties
    var dataSource: CollectionViewDiffableDataSource<String, ItemType>!
    let viewModel: ListViewModel<ItemType>
    var sections: [Section] { [] }
    
    override var scrollViewAvoidingTabBar: UIScrollView? {collectionView}
    
    lazy var collectionView: BaseCollectionView = {
        let collectionView = BaseCollectionView(frame: .zero, collectionViewLayout: createLayout())
        return collectionView
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        return control
    }()
    
    init(viewModel: ListViewModel<ItemType>) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
        collectionView.refreshControl = refreshControl
        
        registerCellAndSupplementaryViews()
        configureDataSource()
    }
    
    func registerCellAndSupplementaryViews() {
        collectionView.registerCells([Cell.self])
        let headerViewClasses = sections.reduce([SectionHeaderView.Type]()) { (result, header) in
            if result.contains(where: {$0 == header.headerViewClass}) {return result}
            return result + [header.headerViewClass]
        }
        
        for viewClass in headerViewClasses {
            collectionView.register(viewClass.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: viewClass))
        }
        
        let footerViewClasses = sections.reduce([SectionFooterView.Type]()) { (result, header) in
            if result.contains(where: {$0 == header.footerViewClass}) {return result}
            return result + [header.footerViewClass]
        }
        
        for viewClass in footerViewClasses {
            collectionView.register(viewClass.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: String(describing: viewClass))
        }
    }
    
    // MARK: - Binding
    override func bind() {
        super.bind()
        viewModel.dataDidChange
            .subscribe(onNext: { (_) in
                let snapshot = self.mapDataToSnapshot()
                self.dataSource.apply(snapshot)
                DispatchQueue.main.async {
                    self.dataDidLoad()
                }
            })
            .disposed(by: disposeBag)
        
        collectionView.delegate = self
    }
    
    func mapDataToSnapshot() -> DiffableDataSourceSnapshot<String, ItemType> {
        var snapshot = DiffableDataSourceSnapshot<String, ItemType>()
        guard let section = sections.first?.headerTitle else {
            return snapshot
        }
        snapshot.appendSections([section])
        var items = viewModel.items
        switch viewModel.state.value {
        case .loading:
            items += [ItemType.placeholder(at: 0), ItemType.placeholder(at: 1)]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: section)
        return snapshot
    }
    
    func dataDidLoad() {
        let numberOfSections = dataSource.numberOfSections(in: collectionView)
        guard numberOfSections > 0,
              let footer = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(row: 0, section: numberOfSections - 1)) as? SectionFooterView
        else {
            return
        }
        
        footer.setUp(state: viewModel.state.value, isListEmpty: viewModel.isListEmpty)
//        collectionView.collectionViewLayout.invalidateLayout()
        footer.setNeedsDisplay()
    }
    
    func itemDidSelect(_ item: ItemType) {
        
    }
    
    // MARK: - Layout
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { (sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            self.createLayoutForSection(sectionIndex, environment: env)
        }
    }
    
    func createLayoutForSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let sectionInfo = sections[sectionIndex]
        
        let group: NSCollectionLayoutGroup
        // 1 columns
        if env.container.contentSize.width < 536 {
            group = createLayoutForGroupOnSmallScreen(sectionIndex: sectionIndex, env: env)
        // 2 columns
        } else {
            group = createLayoutForGroupOnLargeScreen(sectionIndex: sectionIndex, env: env)
        }
        
        group.contentInsets = sectionInfo.contentInsets
        
        let section = NSCollectionLayoutSection(group: group)
        
        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        if !sections[sectionIndex].headerTitle.isEmpty,
           let headerLayout = sections[sectionIndex].headerLayout {
            supplementaryItems.append(headerLayout)
        }
        
        if let footerLayout = sections[sectionIndex].footerLayout {
            supplementaryItems.append(footerLayout)
        }
        
        if !supplementaryItems.isEmpty {
            section.boundarySupplementaryItems = supplementaryItems
        }
        
        if let interGroupSpacing = sections[sectionIndex].interGroupSpacing {
            section.interGroupSpacing = interGroupSpacing
        }
        
        if let orthogonalScrollingBehavior = sections[sectionIndex].orthogonalScrollingBehavior {
            section.orthogonalScrollingBehavior = orthogonalScrollingBehavior
        }
        
        return section
    }
    
    func createLayoutForGroupOnSmallScreen(sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        let sectionInfo = sections[sectionIndex]
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: sectionInfo.itemHeight)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(env.container.contentSize.width), heightDimension: .estimated(200))
        
        return NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
    }
    
    func createLayoutForGroupOnLargeScreen(sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        let sectionInfo = sections[sectionIndex]
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: sectionInfo.itemHeight)
        
        let leadingItem = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let trailingItem = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute((env.container.contentSize.width - sectionInfo.horizontalInterItemSpacing.spacing - sectionInfo.contentInsets.leading - sectionInfo.contentInsets.trailing)/2), heightDimension: itemSize.heightDimension)
        
        let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [leadingItem])
        
        let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [trailingItem])
        
        let combinedGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: itemSize.heightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: combinedGroupSize, subitems: [leadingGroup, trailingGroup])
        group.interItemSpacing = sectionInfo.horizontalInterItemSpacing
        return group
    }
    
    // MARK: - Datasource
    private func configureDataSource() {
        dataSource = CollectionViewDiffableDataSource<String, ItemType>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell? in
            self.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }
                
        dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            self.configureSupplementaryView(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
    }
    
    func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: Cell.self), for: indexPath) as? Cell
        cell?.setUp(with: item as! Cell.T)
        if item.id.starts(with: "placeholder") {
            cell?.showLoading()
        } else {
            cell?.hideLoading()
        }
        return cell ?? UICollectionViewCell()
    }
    
    func configureSupplementaryView(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        if kind == UICollectionView.elementKindSectionHeader {
            return configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        }
        if kind == UICollectionView.elementKindSectionFooter {
            return configureFooterForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        }
        return nil
    }
    
    func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        guard sections.count > indexPath.section else {
            return nil
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: String(describing: sections[indexPath.section].headerViewClass),
            for: indexPath) as? SectionHeaderView
        
        view?.setUp(headerTitle: sections[indexPath.section].headerTitle, headerFont: sections[indexPath.section].headerFont)
        return view
    }
    
    func configureFooterForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        guard sections.count > indexPath.section else {
            return nil
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: String(describing: sections[indexPath.section].footerViewClass),
            for: indexPath) as? SectionFooterView
        
        return view
    }
    
    // MARK: - Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {return}
        itemDidSelect(item)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            // Load more
            if viewModel.isPaginationEnabled {
                if self.collectionView.contentOffset.y > 0 {
                    let numberOfSections = collectionView.numberOfSections
                    guard numberOfSections > 0 else {return}
                    
                    guard let indexPath = collectionView.indexPathsForVisibleItems.filter({$0.section == numberOfSections - 1}).max(by: {$0.row < $1.row})
                    else {
                        return
                    }
                    
                    if indexPath.row >= collectionView.numberOfItems(inSection: collectionView.numberOfSections - 1) - 5 {
                        viewModel.fetchNext()
                    }
                }
            }
        }
        
    }
    
    // MARK: - Actions
    @objc func refresh(_ sender: Any) {
        refreshControl.endRefreshing()
        viewModel.refresh()
    }
}
