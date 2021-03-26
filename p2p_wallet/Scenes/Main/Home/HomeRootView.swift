//
//  HomeRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import UIKit
import Action
import BECollectionView

class HomeRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: HomeViewModel
    
    // MARK: - Subviews
    lazy var collectionView: HomeCollectionView = {
        let collectionView = HomeCollectionView(viewModel: viewModel.walletsVM)
        collectionView.delegate = self
        collectionView.walletCellEditAction = Action<Wallet, Void> {wallet in
            self.viewModel.navigationSubject.onNext(.walletSettings(wallet: wallet))
            return .just(())
        }
        collectionView.collectionView.contentInset.modify(dBottom: 16)
        return collectionView
    }()
    
    // MARK: - Initializers
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        layout()
        bind()
        collectionView.refresh()
    }
    
    // MARK: - Layout
    private func layout() {
        // configure header
        addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
    }
    
    private func bind() {
        
    }
}

extension HomeRootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionView, didSelect item: AnyHashable) {
        guard let wallet = item as? Wallet else {return}
        viewModel.navigationSubject.onNext(.walletDetail(wallet: wallet))
    }
}
