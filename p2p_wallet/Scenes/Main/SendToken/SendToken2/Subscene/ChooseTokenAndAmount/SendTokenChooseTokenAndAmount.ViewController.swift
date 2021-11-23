//
//  SendTokenChooseTokenAndAmount.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import UIKit

extension SendTokenChooseTokenAndAmount {
    class ViewController: SendToken2.BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseTokenAndAmountViewModelType
        
        // MARK: - Properties
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseTokenAndAmountViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func loadView() {
            view = RootView(viewModel: viewModel)
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
            case .chooseWallet:
//                let vc = Detail.ViewController()
//                present(vc, completion: nil)
                break
            }
        }
    }
}
