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
        override func setUp() {
            super.setUp()
            navigationBar.titleLabel.text = L10n.send
            
            let rootView = RootView(viewModel: viewModel)
            view.addSubview(rootView)
            rootView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            rootView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
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
