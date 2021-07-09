//
//  MyProductsRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import UIKit
import Action
import BECollectionView

class MyProductsRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: MyProductsViewModel
    
    // MARK: - Subviews
    lazy var collectionView: MyProductsCollectionView = {
        let collectionView = MyProductsCollectionView(repository: viewModel.walletsRepository)
        collectionView.delegate = self
        collectionView.walletCellEditAction = Action<Wallet, Void> {[unowned self] wallet in
            self.viewModel.showWalletSettings(wallet: wallet)
            return .just(())
        }
        collectionView.showHideHiddenWalletsAction = CocoaAction { [weak self] in
            self?.viewModel.walletsRepository.toggleIsHiddenWalletShown()
            return .just(())
        }
        return collectionView
    }()
    
    // MARK: - Initializers
    init(viewModel: MyProductsViewModel) {
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
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.allMyTokens, textSize: 21, weight: .semibold),
                UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .h5887ff)
                    .padding(.init(all: 10), backgroundColor: .eff3ff, cornerRadius: 12)
                    .onTap(viewModel, action: #selector(MyProductsViewModel.addNewWallet))
            ])
                .padding(.init(all: 20)),
            collectionView
        ])
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    private func bind() {
        
    }
}

extension MyProductsRootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let wallet = item as? Wallet, let pubkey = wallet.pubkey else {return}
        self.viewModel.showWalletDetail(pubkey: pubkey, symbol: wallet.token.symbol)
    }
}
