//
//  VerifySecurityKeys.RootView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.11.21.
//

import UIKit
import RxSwift

extension VerifySecurityKeys {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        @Injected private var viewModel: VerifySecurityKeysViewModelType
        
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
    }
}
