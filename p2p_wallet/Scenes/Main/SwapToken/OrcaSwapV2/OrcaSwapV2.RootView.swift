//
//  OrcaSwapV2.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import UIKit
import RxSwift

extension OrcaSwapV2 {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: OrcaSwapV2ViewModelType
        
        // MARK: - Subviews
        
        // MARK: - Methods
        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
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
}
