//
//  CollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import RxSwift

struct CollectionViewItem<T: Hashable>: Hashable {
    var placeholderIndex: Int?
    var value: T?
    
    var isPlaceholder: Bool {placeholderIndex != nil}
}

protocol CollectionViewDelegate: class {
    func dataDidLoad()
}

class CollectionView<T: Hashable, ViewModel: ListViewModel<T>>: BEView {
    // MARK: - Property
    let disposeBag = DisposeBag()
    let viewModel: ViewModel
    let sections: [CollectionViewSection]
    
    var dataSource: UICollectionViewDiffableDataSource<String, CollectionViewItem<T>>!
    var itemDidSelect: ((T) -> Void)?
    
    weak var delegate: CollectionViewDelegate?
    
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
    init(viewModel: ViewModel, sections: [CollectionViewSection]) {
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(collectionViewDidTouch(_:)))
        collectionView.addGestureRecognizer(tapGesture)
    }
    
    func bind() {
        var observable = viewModel.dataDidChange
        
        if SystemVersion.isIOS13() {
            observable = observable
                .debounce(.nanoseconds(1), scheduler: MainScheduler.instance)
        }
        observable
            .subscribe(onNext: { [unowned self] (_) in
                let snapshot = self.mapDataToSnapshot()
                self.dataSource.apply(snapshot)
                DispatchQueue.main.async {
                    self.dataDidLoad()
                }
            })
            .disposed(by: disposeBag)
        
        collectionView.rx.didEndDecelerating
            .subscribe(onNext: { [unowned self] in
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
        
//        collectionView.rx.itemSelected
//            .subscribe(onNext: {[unowned self] indexPath in
//                guard let item = self.dataSource.itemIdentifier(for: indexPath) else {return}
//                if item.isPlaceholder {
//                    return
//                }
//                if let item = item.value {
//                    self.itemDidSelect?(item)
//                }
//            })
//            .disposed(by: disposeBag)
    }
    
    func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, CollectionViewItem<T>> {
        var snapshot = NSDiffableDataSourceSnapshot<String, CollectionViewItem<T>>()
        let section = sections.first?.header?.title ?? ""
        snapshot.appendSections([section])
        let items = viewModel.searchResult == nil ? filter(viewModel.items) : filter(viewModel.searchResult!)
        var wrappedItems = items.map {CollectionViewItem(placeholderIndex: nil, value: $0)}
        switch viewModel.state.value {
        case .loading:
            wrappedItems += [
                CollectionViewItem(placeholderIndex: 0, value: nil),
                CollectionViewItem(placeholderIndex: 1, value: nil)
            ]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(wrappedItems, toSection: section)
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
        
        delegate?.dataDidLoad()
    }
    
    // MARK: - Actions
    @objc func refresh(_ sender: Any) {
        refreshControl.endRefreshing()
        viewModel.refresh()
    }
    
    // MARK: - Datasource
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<String, CollectionViewItem<T>>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: CollectionViewItem<T>) -> UICollectionViewCell? in
            self.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }
                
        dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            self.configureSupplementaryView(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
    }
    
    func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: CollectionViewItem<T>) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: sections[indexPath.section].cellType), for: indexPath)
        
        setUpCell(cell: cell, withItem: item.value)
        
        if let cell = cell as? LoadableView {
            if item.isPlaceholder {
                cell.showLoading()
            } else {
                cell.hideLoading()
            }
        }
        
        return cell
    }
    
    func setUpCell(cell: UICollectionViewCell, withItem item: T?) {
        if let cell = cell as? ListCollectionCell<T>, let item = item {
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
    
    @objc func collectionViewDidTouch(_ sender: UIGestureRecognizer) {
        if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
            guard let item = self.dataSource.itemIdentifier(for: indexPath) else {return}
            if item.isPlaceholder {
                return
            }
            if let item = item.value {
                self.itemDidSelect?(item)
            }
        } else {
            print("collection view was tapped")
        }
    }
    
    // MARK: - Helpers
    func headerForSection(_ section: Int) -> UICollectionReusableView?
    {
        collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: section))
    }
    
    func footerForSection(_ section: Int) -> UICollectionReusableView?
    {
        collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(row: 0, section: section))
    }
}
