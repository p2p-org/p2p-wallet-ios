//
//  TokenSettingsRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import UIKit
import Action

class SettingsCollectionView: CollectionView<TokenSettings> {
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: CollectionViewItem<TokenSettings>) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        (cell as! TokenSettingsCell).toggleVisibilityAction = CocoaAction {
            (self.viewModel as! TokenSettingsViewModel).toggleHideWallet()
            return .just(())
        }
        return cell
    }
}

class TokenSettingsRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: TokenSettingsViewModel
    lazy var collectionView = SettingsCollectionView(viewModel: viewModel, sections: [
        CollectionViewSection(
            cellType: TokenSettingsCell.self,
            interGroupSpacing: 1,
            itemHeight: .estimated(72),
            contentInsets: .zero,
            horizontalInterItemSpacing: .fixed(0)
        )
    ])
    
    // MARK: - Subviews
    
    // MARK: - Initializers
    init(viewModel: TokenSettingsViewModel) {
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
        collectionView.autoPinEdgesToSuperviewSafeArea()
    }
    
    private func bind() {
        
    }
}
