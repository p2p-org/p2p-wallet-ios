//
//  ChooseWallet.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import UIKit
import RxSwift
import BECollectionView

extension ChooseWallet {
    class RootView: BEView {
        // MARK: - Constants
        
        // MARK: - Properties
        let viewModel: ViewModel
        
        // MARK: - Subviews
        private lazy var searchBar: BESearchBar = {
            let searchBar = BESearchBar(fixedHeight: 36, cornerRadius: 12)
            
            searchBar.textFieldBgColor = .grayPanel
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
        private lazy var collectionView: CollectionView = {
            let collectionView = CollectionView(
                viewModel: viewModel
            )
            collectionView.keyboardDismissMode = .onDrag
            return collectionView
        }()
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
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
            viewModel.reload()
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
        
        // MARK: - Helper
        func forwardDelegate(to delegate: BECollectionViewDelegate) {
            collectionView.delegate = delegate
        }
    }
}

extension ChooseWallet.RootView: BESearchBarDelegate {
    func beSearchBar(_ searchBar: BESearchBar, searchWithKeyword keyword: String) {
        viewModel.search(keyword: keyword)
    }
    
    func beSearchBarDidBeginSearching(_ searchBar: BESearchBar) {
        
    }
    
    func beSearchBarDidEndSearching(_ searchBar: BESearchBar) {
        
    }
    
    func beSearchBarDidCancelSearching(_ searchBar: BESearchBar) {
        searchBar.clear()
    }
}
