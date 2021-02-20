//
//  CreateOrRestoreWalletContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class CreateOrRestoreWalletContainer {
    // from parent
    let handler: CreateOrRestoreWalletHandler
    let accountStorage: KeychainAccountStorage
    
    // longlived dependency
    let viewModel: CreateOrRestoreWalletViewModel
    
    init(
        accountStorage: KeychainAccountStorage,
        handler: CreateOrRestoreWalletHandler
    ) {
        self.viewModel = CreateOrRestoreWalletViewModel()
        self.accountStorage = accountStorage
        self.handler = handler
    }
    
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController {
        CreateOrRestoreWalletViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeCreateWalletViewController() -> CreateWalletViewController
    {
        let container = CreateWalletContainer(accountStorage: accountStorage, handler: handler)
        return container.makeCreateWalletViewController()
    }
    
    func makeRestoreWalletViewController() -> RestoreWalletViewController
    {
        let container = RestoreWalletContainer(accountStorage: accountStorage, handler: handler)
        return container.makeRestoreWalletViewController()
    }
}

extension CreateOrRestoreWalletContainer: CreateOrRestoreWalletScenesFactory {}
