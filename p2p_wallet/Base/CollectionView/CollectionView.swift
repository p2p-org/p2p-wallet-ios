//
//  CollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import RxSwift

class CollectionView<T: ListItemType>: BEView {
    // MARK: - Property
    let disposeBag = DisposeBag()
    let viewModel: ListViewModel<T>
    let sections: [CollectionViewSection]
    
    var dataSource: UICollectionViewDiffableDataSource<String, T>!
    var itemDidSelect: ((T) -> Void)?
    
    // MARK: - Subviews
    lazy var collectionView: BaseCollectionView = {
        let collectionView = BaseCollectionView(frame: .zero, collectionViewLayout: sections.createLayout())
        return collectionView
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        return control
    }()
    
    // MARK: - Initializers
    init(viewModel: ListViewModel<T>, sections: [CollectionViewSection]) {
        self.viewModel = viewModel
        self.sections = sections
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewSafeArea()
        collectionView.refreshControl = refreshControl
        
        sections.forEach {$0.registerCellAndSupplementaryViews(in: collectionView)}
        configureDataSource()
        
        bind()
    }
    
    func bind() {
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
                self.itemDidSelect?(item)
            })
            .disposed(by: disposeBag)
    }
    
    func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, T> {
        var snapshot = NSDiffableDataSourceSnapshot<String, T>()
        let section = sections.first?.header?.title ?? ""
        snapshot.appendSections([section])
        var items = viewModel.searchResult == nil ? filter(viewModel.items) : filter(viewModel.searchResult!)
        switch viewModel.state.value {
        case .loading:
            items += [T.placeholder(at: items.count), T.placeholder(at: items.count + 1)]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: section)
        return snapshot
    }
    
    func filter(_ items: [T]) -> [T] {
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
    
    // MARK: - Actions
    @objc func refresh(_ sender: Any) {
        refreshControl.endRefreshing()
        viewModel.refresh()
    }
    
    // MARK: - Datasource
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<String, T>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: T) -> UICollectionViewCell? in
            self.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }
                
        dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            self.configureSupplementaryView(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
    }
    
    func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: T) -> UICollectionViewCell {
        
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
    
    func setUpCell(cell: UICollectionViewCell, withItem item: T) {
        if let cell = cell as? ListCollectionCell<T> {
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
}
