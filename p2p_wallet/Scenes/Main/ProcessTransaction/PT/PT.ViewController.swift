//
//  PT.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import UIKit

extension PT {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        @Injected private var viewModel: PTViewModelType
        
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
            guard let scene = scene else {return}
            switch scene {
            case .detail:
//                let vc = Detail.ViewController()
//                present(vc, completion: nil)
                break
            case .explorer(transactionID: let transactionID):
                break
            }
        }
    }
}
