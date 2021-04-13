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
    private lazy var searchBar = BESearchBar(forAutoLayout: ())
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
        collectionView.autoPinEdge(.top, to: .bottom, of: searchBar)
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
