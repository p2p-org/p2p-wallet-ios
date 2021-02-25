//
//  CollectionVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation
import RxSwift

protocol ListItemType: Hashable {
    static func placeholder(at index: Int) -> Self
    var id: String {get}
}

extension ListItemType {
    static func placeholderId(at index: Int) -> String {
        "placeholder#\(index)"
    }
}

class ListCollectionCell<T: ListItemType>: BaseCollectionViewCell {
    func setUp(with item: T) {}
}

class CollectionVC<ItemType: ListItemType>: BaseVC {
    // MARK: - Properties
    var dataSource: UICollectionViewDiffableDataSource<String, ItemType>!
    let viewModel: ListViewModel<ItemType>
    var sections: [CollectionViewSection] { [] }
    
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
        super.init()
    }
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewSafeArea()
        collectionView.refreshControl = refreshControl
        
        registerCellAndSupplementaryViews()
        configureDataSource()
    }
    
    func registerCellAndSupplementaryViews() {
        // register cells
        let cellClasses = sections.map {$0.cellType}
        collectionView.registerCells(cellClasses)
        
        // register headers
        let headerViewClasses = sections.reduce([SectionHeaderView.Type]()) { (result, section) in
            if result.contains(where: {$0 == section.header?.viewClass}) {return result}
            if let headerViewClass = section.header?.viewClass {
                return result + [headerViewClass]
            }
            return result
        }
        
        for viewClass in headerViewClasses {
            collectionView.register(viewClass.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: viewClass))
        }
        
        // register footer
        let footerViewClasses = sections.reduce([SectionFooterView.Type]()) { (result, section) in
            if result.contains(where: {$0 == section.footer?.viewClass}) {return result}
            if let footerViewClass = section.footer?.viewClass {
                return result + [footerViewClass]
            }
            return result
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
        
        collectionView.rx.didEndDecelerating
            .subscribe(onNext: {
                // Load more
                if self.viewModel.isPaginationEnabled {
                    if self.collectionView.contentOffset.y > 0 {
                        let numberOfSections = self.collectionView.numberOfSections
                        guard numberOfSections > 0 else {return}
                        
                        guard let indexPath = self.collectionView.indexPathsForVisibleItems.filter({$0.section == numberOfSections - 1}).max(by: {$0.row < $1.row})
                        else {
                            return
                        }
                        
                        if indexPath.row >= self.collectionView.numberOfItems(inSection: self.collectionView.numberOfSections - 1) - 5 {
                            self.viewModel.fetchNext()
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: {indexPath in
                guard let item = self.dataSource.itemIdentifier(for: indexPath) else {return}
                if item.id.starts(with: "placeholder") {
                    return
                }
                self.itemDidSelect(item)
            })
            .disposed(by: disposeBag)
    }
    
    func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, ItemType> {
        var snapshot = NSDiffableDataSourceSnapshot<String, ItemType>()
        let section = sections.first?.header?.title ?? ""
        snapshot.appendSections([section])
        var items = viewModel.searchResult == nil ? filter(viewModel.items) : filter(viewModel.searchResult!)
        switch viewModel.state.value {
        case .loading:
            items += [ItemType.placeholder(at: items.count), ItemType.placeholder(at: items.count + 1)]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: section)
        return snapshot
    }
    
    func filter(_ items: [ItemType]) -> [ItemType] {
        items
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
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            self.createLayoutForSection(sectionIndex, environment: env)
        }
        
        for section in sections where section.background != nil {
            layout.register(section.background.self, forDecorationViewOfKind: String(describing: section.background!))
        }
        
        return layout
    }
    
    func createLayoutForSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let section = sections[sectionIndex]
        return section.layout(environment: env)
    }
    
    // MARK: - Datasource
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<String, ItemType>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell? in
            self.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }
                
        dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            self.configureSupplementaryView(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
    }
    
    func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: ItemType) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: sections[indexPath.section].cellType), for: indexPath)
        
        setUpCell(cell: cell, withItem: item)
        
        if let cell = cell as? LoadableView {
            if item.id.starts(with: "placeholder") {
                cell.showLoading()
            } else {
                cell.hideLoading()
            }
        }
        
        return cell
    }
    
    func setUpCell(cell: UICollectionViewCell, withItem item: ItemType) {
        if let cell = cell as? ListCollectionCell<ItemType> {
            cell.setUp(with: item)
        }
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
            withReuseIdentifier: String(describing: sections[indexPath.section].header!.viewClass),
            for: indexPath) as? SectionHeaderView
        
        view?.setUp(headerTitle: sections[indexPath.section].header!.title, headerFont: sections[indexPath.section].header!.titleFont)
        return view
    }
    
    func configureFooterForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        guard sections.count > indexPath.section else {
            return nil
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: String(describing: sections[indexPath.section].footer!.viewClass),
            for: indexPath) as? SectionFooterView
        
        return view
    }
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> ItemType? {
        viewModel.itemAtIndex(indexPath.row)
    }
    
    // MARK: - Actions
    @objc func refresh(_ sender: Any) {
        refreshControl.endRefreshing()
        viewModel.refresh()
    }
}
