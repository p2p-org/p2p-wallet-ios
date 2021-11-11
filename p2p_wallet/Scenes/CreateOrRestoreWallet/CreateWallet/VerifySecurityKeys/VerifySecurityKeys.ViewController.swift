//
//  VerifySecurityKeys.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.11.21.
//

import Foundation
import UIKit

extension VerifySecurityKeys {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        private let viewModel: VerifySecurityKeysViewModelType
        
        // MARK: - Properties
        
        // MARK: - Methods
        init(viewModel: VerifySecurityKeysViewModelType) {
            self.viewModel = viewModel
        }
        
        override func loadView() {
            view = RootView()
        }
        
        override func setUp() {
            super.setUp()
            
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .detail:
                break
            default:
                break
            }
        }
    }
}
