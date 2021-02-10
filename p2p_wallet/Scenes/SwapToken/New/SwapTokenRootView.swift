//
//  SwapTokenRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import UIKit

class SwapTokenRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: SwapTokenViewModel
    
    // MARK: - Subviews
    
    // MARK: - Initializers
    init(viewModel: SwapTokenViewModel) {
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
        
    }
    
    private func bind() {
        
    }
}
