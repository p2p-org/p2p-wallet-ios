//
//  Authentication.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Foundation
import UIKit

extension Authentication {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        @Injected private var viewModel: AuthenticationViewModelType
        
        // MARK: - Properties
        override var title: String? {
            didSet {
                
            }
        }
        
        var isIgnorable: Bool = false {
            didSet {
                
            }
        }
        
        var useBiometry: Bool = true {
            didSet {
                
            }
        }
        
        // MARK: - Callbacks
        var onSuccess: (() -> Void)?
        var onCancel: (() -> Void)?
        
        // MARK: - Subviews
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .resetPincodeWithASeedPhrase:
                break
            default:
                break
            }
        }
    }
}
