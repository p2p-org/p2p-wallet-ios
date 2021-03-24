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
    private lazy var collectionView = ChooseWalletCollectionView(viewModel: viewModel)
    
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
        addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges(with: .init(x: .defaultPadding, y: 0))
    }
    
    private func bind() {
        
    }
}
