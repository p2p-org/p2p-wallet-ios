//
//  OrcaSwapV2.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import UIKit

extension OrcaSwapV2 {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        @Injected private var viewModel: OrcaSwapV2ViewModelType
        
        // MARK: - Properties
        
        // MARK: - Methods
        override func loadView() {
            view = RootView()
        }
        
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
//            switch scene {
//            case .detail:
//                break
//            default:
//                break
//            }
        }
    }
}
