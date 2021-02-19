//
//  CreateOrRestoreWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

class CreateOrRestoreWalletViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: CreateOrRestoreWalletViewModel
    var childNavigationController: BENavigationController!
    
    // MARK: - Initializer
    init(viewModel: CreateOrRestoreWalletViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: CreateOrRestoreWalletNavigatableScene) {
        switch scene {
        case .welcome:
            removeAllChilds()
            add(child: WelcomeVC())
        case .createWallet:
            let createWalletViewController = DependencyContainer.shared.makeCreateWalletViewController()
            let nc = BENavigationController(rootViewController: createWalletViewController)
            let vc = WLModalWrapperVC(wrapped: nc)
            vc.isModalInPresentation = true
            present(vc, animated: true, completion: nil)
        case .restoreWallet:
            let restoreWaleltViewController = DependencyContainer.shared.makeRestoreWalletViewController()
            let nc = BENavigationController(rootViewController: restoreWaleltViewController)
            let vc = WLModalWrapperVC(wrapped: nc)
            vc.isModalInPresentation = true
            present(vc, animated: true, completion: nil)
        }
    }
}
