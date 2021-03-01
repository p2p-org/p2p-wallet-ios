//
//  TokenSettingsRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import UIKit

class TokenSettingsRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: TokenSettingsViewModel
    lazy var collectionView: TokenSettingsCollectionView = {
        let collectionView = TokenSettingsCollectionView(viewModel: viewModel, sections: [
            CollectionViewSection(
                cellType: TokenSettingsCell.self,
                interGroupSpacing: 1,
                itemHeight: .estimated(72),
                contentInsets: .zero,
                horizontalInterItemSpacing: .fixed(0)
            )
        ])
        collectionView.itemDidSelect = {
            switch $0 {
            case .close:
                self.viewModel.navigationSubject.onNext(.closeConfirmation)
            default:
                return
            }
        }
        return collectionView
    }()
    
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
