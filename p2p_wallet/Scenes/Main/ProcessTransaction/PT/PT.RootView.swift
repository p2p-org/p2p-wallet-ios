//
//  PT.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import UIKit
import RxSwift

extension PT {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        @Injected private var viewModel: PTViewModelType
        
        // MARK: - Subviews
        
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
        
        // MARK: - Actions
        @objc private func showDetail() {
            viewModel.navigate(to: .detail)
        }
    }
}
