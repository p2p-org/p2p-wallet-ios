//
//  CreateSecurityKeysViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Foundation
import UIKit

extension CreateSecurityKeys {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: CreateSecurityKeysViewModelType
        
        // MARK: - Subviews
        lazy var backButton = UIImageView(width: 36, height: 36, image: .backSquare)
            .onTap(self, action: #selector(back))
        
        // MARK: - Methods
        override func loadView() {
            view = RootView(backButton: backButton)
        }
        
        override func bind() {
            super.bind()
            viewModel.errorSignal
                .emit(onNext: {[weak self] error in
                    self?.showAlert(title: L10n.error, message: error)
                })
                .disposed(by: disposeBag)
        }
    }
}
