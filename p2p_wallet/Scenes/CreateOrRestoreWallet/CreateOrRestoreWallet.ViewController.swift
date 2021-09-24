//
//  CreateOrRestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

extension CreateOrRestoreWallet {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        @Injected private var viewModel: CreateOrRestoreWalletViewModelType
        
        // MARK: - Properties
        var childNavigationController: BENavigationController!
        
        // MARK: - Methods
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene) {
            switch scene {
            case .welcome:
                removeAllChilds()
                add(child: WelcomeVC())
            case .createWallet:
                let vc = CreateWallet.ViewController()
                vc.isModalInPresentation = true
                present(vc, animated: true, completion: nil)
            case .restoreWallet:
                let vc = RestoreWallet.ViewController()
                show(vc, sender: nil)
            }
        }
    }
}
