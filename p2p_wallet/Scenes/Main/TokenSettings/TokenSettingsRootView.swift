//
//  TokenSettingsRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import UIKit
import BECollectionView

class TokenSettingsRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: TokenSettingsViewModel
    lazy var collectionView: BECollectionView = {
        let collectionView = BECollectionView(sections: [
            TokenSettingsSection(
                index: 0,
                layout: .init(
                    cellType: TokenSettingsCell.self,
                    interGroupSpacing: 1,
                    itemHeight: .estimated(72),
                    contentInsets: .zero,
                    horizontalInterItemSpacing: .fixed(0)
                ),
                viewModel: viewModel
            )
        ])
        collectionView.contentInset.modify(dTop: 10)
        collectionView.delegate = self
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

extension TokenSettingsRootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionView, didSelect item: AnyHashable) {
        guard let item = item as? TokenSettings else {
            return
        }
        switch item {
        case .close(let isEnabled):
            if isEnabled {
                viewModel.navigationSubject.onNext(.closeConfirmation)
            }
        default:
            return
        }
    }
}
