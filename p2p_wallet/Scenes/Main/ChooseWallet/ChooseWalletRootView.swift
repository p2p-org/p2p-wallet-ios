//
//  ChooseWalletRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import UIKit
import BECollectionView

class ChooseWalletRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: ChooseWalletViewModel
    
    // MARK: - Subviews
    private lazy var searchBar: BESearchBar = {
        let searchBar = BESearchBar(fixedHeight: 36, cornerRadius: 12)
        
        searchBar.textFieldBgColor = .f6f6f8
        searchBar.placeholder = L10n.searchToken
        
        searchBar.leftViewWidth = 20.57 + 12 + 12
        searchBar.magnifyingIconImageView.image = .search
        searchBar.magnifyingIconImageView.tintColor = .a3a5ba
        searchBar.magnifyingIconSize = 20.57
        
        searchBar.tintColor = .h5887ff
        searchBar.cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        
        searchBar.delegate = self
        
        return searchBar
    }()
    private lazy var collectionView: ChooseWalletCollectionView = {
        let collectionView = ChooseWalletCollectionView(
            viewModel: viewModel,
            firstSectionFilter: viewModel.firstSectionFilter
        )
        collectionView.delegate = self
        return collectionView
    }()
    
    // MARK: - Initializers
    init(viewModel: ChooseWalletViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        layout()
        bind()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
    }
    
    // MARK: - Layout
    private func layout() {
        addSubview(searchBar)
        searchBar.autoPinEdgesToSuperviewEdges(with: .init(top: .defaultPadding, left: 16, bottom: 0, right: 16), excludingEdge: .bottom)
        
        addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges(with: .init(x: .defaultPadding, y: 0), excludingEdge: .top)
        collectionView.autoPinEdge(.top, to: .bottom, of: searchBar, withOffset: 10)
    }
    
    private func bind() {
        
    }
}

extension ChooseWalletRootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionView, didSelect item: AnyHashable) {
        guard let item = item as? Wallet else { return }
        viewModel.selectedWallet.onNext(item)
    }
}

extension ChooseWalletRootView: BESearchBarDelegate {
    func beSearchBar(_ searchBar: BESearchBar, searchWithKeyword keyword: String) {
        print("searchBar: searchWithKeyword: \(keyword)")
        viewModel.search(keyword: keyword)
    }
    
    func beSearchBarDidBeginSearching(_ searchBar: BESearchBar) {
        print("searchBar: searchDidBegin")
        viewModel.searchDidBegin()
    }
    
    func beSearchBarDidEndSearching(_ searchBar: BESearchBar) {
        print("searchBar: searchDidEnd")
        viewModel.searchDidEnd()
    }
    
    func beSearchBarDidCancelSearching(_ searchBar: BESearchBar) {
        print("searchBar: searchDidEnd: searchDidCancel")
        viewModel.searchDidEnd()
    }
}
