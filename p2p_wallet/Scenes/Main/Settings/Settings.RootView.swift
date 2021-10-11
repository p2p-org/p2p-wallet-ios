//
//  Settings.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import UIKit
import RxSwift

extension Settings {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        @Injected private var viewModel: SettingsViewModelType
        
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
