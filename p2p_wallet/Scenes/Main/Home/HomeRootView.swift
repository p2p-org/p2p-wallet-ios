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
        collectionView.receiveAction = viewModel.navigationAction(scene: .receiveToken)
        collectionView.sendAction = viewModel.navigationAction(scene: .scanQr)
        collectionView.swapAction = viewModel.navigationAction(scene: .swapToken)
        collectionView.showAllProductsAction = viewModel.navigationAction(scene: .allProducts)
        collectionView.walletCellEditAction = Action<Wallet, Void> { [weak self] wallet in
            self?.viewModel.navigationSubject.onNext(.walletSettings(wallet: wallet))
            return .just(())
        }
        collectionView.showHideHiddenWalletsAction = CocoaAction { [weak self] in
            self?.viewModel.walletsRepository.toggleIsHiddenWalletShown()
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
    func beCollectionView(collectionView: BECollectionView, didSelect item: AnyHashable) {
        guard let wallet = item as? Wallet else {return}
        viewModel.navigationSubject.onNext(.walletDetail(wallet: wallet))
    }
}
