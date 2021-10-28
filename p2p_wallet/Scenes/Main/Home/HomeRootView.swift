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
    lazy var collectionView: WalletsCollectionView = {
        let collectionView = WalletsCollectionView(
            walletsRepository: viewModel.walletsRepository,
            activeWalletsSection: .init(
                index: 0,
                viewModel: viewModel.walletsRepository,
                cellType: HomeWalletCell.self
            ),
            hiddenWalletsSection: HiddenWalletsSection(
                index: 1,
                viewModel: viewModel.walletsRepository,
                header: .init(viewClass: HiddenWalletsSectionHeaderView.self)
            )
        )
        collectionView.delegate = self
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
