//
//  SelectRecepient.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.10.2021.
//

import Foundation
import UIKit

extension SelectRecepient {
    class ViewController: WLIndicatorModalVC {
        // MARK: - Dependencies
        @Injected private var viewModel: SelectRecepientViewModelType
        
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
            switch scene {
            case .detail:
                break
            default:
                break
            }
        }
    }
}
