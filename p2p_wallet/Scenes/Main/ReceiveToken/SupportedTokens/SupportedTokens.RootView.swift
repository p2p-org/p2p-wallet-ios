//
//  SupportedTokens.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.01.2022.
//

import UIKit
import RxSwift
import BECollectionView

extension SupportedTokens {
    class RootView: BEView {
        // MARK: - Constants

        // MARK: - Properties
        let viewModel: SupportedTokensViewModelType

        // MARK: - Subviews
        private lazy var searchBar: BESearchBar = {
            let searchBar = BESearchBar(fixedHeight: 36, cornerRadius: 12)

            searchBar.textFieldBgColor = .grayPanel
            searchBar.setUpTextField(placeholderTextColor: .h8e8e93)
            searchBar.leftViewWidth = 20 + 12 + 12
            searchBar.magnifyingIconImageView.image = .standardSearch.withRenderingMode(.alwaysTemplate)
            searchBar.magnifyingIconImageView.tintColor = .h8e8e93
            searchBar.magnifyingIconSize = 20

            searchBar.tintColor = .h5887ff
            searchBar.cancelButton.titleLabel?.font = .systemFont(ofSize: 17)

            searchBar.delegate = self

            return searchBar
        }()
        private lazy var collectionView: CollectionView = {
            let collectionView = CollectionView(viewModel: viewModel)
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
            addSubview(collectionView)

            searchBar.autoPinEdgesToSuperviewEdges(with: .init(top: .defaultPadding, left: 16, bottom: 0, right: 16), excludingEdge: .bottom)

            collectionView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            collectionView.autoPinEdge(.top, to: .bottom, of: searchBar, withOffset: 18)
        }

        private func bind() {

        }

        // MARK: - Helper
        func forwardDelegate(to delegate: BECollectionViewDelegate) {
            collectionView.delegate = delegate
        }
    }
}

extension SupportedTokens.RootView: BESearchBarDelegate {
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
