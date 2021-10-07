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
        let collectionView = HomeCollectionView(walletsRepository: viewModel.walletsRepository)
        collectionView.delegate = self
        collectionView.openProfileAction = viewModel.navigationAction(scene: .profile)
        collectionView.reserveNameAction = viewModel.navigationAction(scene: .reserveName(owner: viewModel.keychainStorage.account?.publicKey.base58EncodedString ?? ""))
        collectionView.buyAction = viewModel.navigationAction(scene: .buyToken)
        collectionView.receiveAction = viewModel.navigationAction(scene: .receiveToken)
        collectionView.sendAction = viewModel.navigationAction(scene: .scanQr)
        collectionView.swapAction = viewModel.navigationAction(scene: .swapToken)
        collectionView.showAllProductsAction = viewModel.navigationAction(scene: .allProducts)
        collectionView.walletCellEditAction = viewModel.navigateToWalletSettingsAction()
        collectionView.showHideHiddenWalletsAction = viewModel.showHideHiddenWalletAction()
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
        addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
    }
    
    private func bind() {
        
    }
}

extension HomeRootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let wallet = item as? Wallet else {return}
        viewModel.showWalletDetail(wallet: wallet)
    }
}
