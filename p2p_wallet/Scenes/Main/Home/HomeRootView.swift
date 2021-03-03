//
//  HomeRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import UIKit
import Action

class HomeRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: HomeViewModel
    
    // MARK: - Subviews
    lazy var collectionView: HomeCollectionView = {
        let collectionView = HomeCollectionView(viewModel: viewModel.homeCollectionViewModel)
        collectionView.itemDidSelect = { item in
            guard let wallet = item.wallet else {return}
            self.viewModel.navigationSubject.onNext(.walletDetail(wallet: wallet))
        }
        collectionView.openProfileAction = viewModel.navigationAction(scene: .profile)
        collectionView.receiveAction = viewModel.navigationAction(scene: .receiveToken)
        collectionView.sendAction = viewModel.navigationAction(scene: .scanQr)
        collectionView.swapAction = viewModel.navigationAction(scene: .swapToken)
        collectionView.showAllProductsAction = viewModel.navigationAction(scene: .allProducts)
        collectionView.walletCellEditAction = Action<Wallet, Void> {wallet in
            self.viewModel.navigationSubject.onNext(.walletSettings(wallet: wallet))
            return .just(())
        }
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
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
    }
    
    // MARK: - Layout
    private func layout() {
        addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
    }
    
    private func bind() {
        
    }
}
