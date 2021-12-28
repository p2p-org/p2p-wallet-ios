//
//  SwapTokenSettings.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import Foundation
import UIKit

extension SwapTokenSettings {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        private let viewModel: NewSwapTokenSettingsViewModelType
        
        // MARK: - Properties
        
        // MARK: - Methods
        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel
        }

        override func loadView() {
            view = RootView(viewModel: viewModel)
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
            case .back:
                navigationController?.popViewController(animated: true)
            case .none:
                break
            }
        }
    }
}
