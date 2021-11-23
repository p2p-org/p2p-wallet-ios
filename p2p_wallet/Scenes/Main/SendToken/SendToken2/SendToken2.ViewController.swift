//
//  SendToken2.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import UIKit
import BEPureLayout

extension SendToken2 {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: SendToken2ViewModelType
        
        // MARK: - Properties
        private let childNavigationController = BENavigationController()
        
        // MARK: - Initializer
        init(viewModel: SendToken2ViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            add(child: childNavigationController, to: view)
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
            case .chooseTokenAndAmount:
                let vm = SendTokenChooseTokenAndAmount.ViewModel()
                let vc = SendTokenChooseTokenAndAmount.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .chooseRecipientAndNetwork:
                break
            case .confirmation:
                break
            }
        }
    }
}
