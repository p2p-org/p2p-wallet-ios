//
//  CreateOrRestoreWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

protocol CreateOrRestoreWalletScenesFactory {
    func makeCreateWalletViewController() -> CreateWalletViewController
    func makeRestoreWalletViewController() -> RestoreWalletViewController
}

class CreateOrRestoreWalletViewController: BaseVC {
    // MARK: - Properties
    let viewModel: CreateOrRestoreWalletViewModel
    let scenesFactory: CreateOrRestoreWalletScenesFactory
    var childNavigationController: BENavigationController!
    
    // MARK: - Initializer
    init(
        viewModel: CreateOrRestoreWalletViewModel,
        scenesFactory: CreateOrRestoreWalletScenesFactory
    ) {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func bind() {
        super.bind()
        viewModel.output.navigation
            .drive(onNext: {[weak self] in self?.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: CreateOrRestoreWalletNavigatableScene) {
        switch scene {
        case .welcome:
            removeAllChilds()
//            add(child: WelcomeVC(createOrRestoreWalletViewModel: viewModel))
            add(child: WelcomeVC.SecondVC(createOrRestoreWalletViewModel: viewModel))
        case .createWallet:
            let vc = scenesFactory.makeCreateWalletViewController()
            vc.isModalInPresentation = true
            present(vc, animated: true, completion: nil)
        case .restoreWallet:
            let restoreWaleltViewController = scenesFactory.makeRestoreWalletViewController()
            show(restoreWaleltViewController, sender: nil)
        }
    }
}
