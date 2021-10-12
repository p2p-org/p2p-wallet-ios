//
//  Backup.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import UIKit
import RxSwift

extension Backup {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        @Injected private var viewModel: BackupViewModelType
        
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
