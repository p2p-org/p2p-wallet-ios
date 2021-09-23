//
//  CreateOrRestoreWalletContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class CreateOrRestoreWalletContainer {
    // from parent
    @Injected private var handler: CreateOrRestoreWalletHandler
    @Injected private var accountStorage: KeychainAccountStorage
    @Injected private var analyticsManager: AnalyticsManagerType
    
    // longlived dependency
    let viewModel = CreateOrRestoreWalletViewModel()
    
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController {
        CreateOrRestoreWalletViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeCreateWalletViewController() -> CreateWalletViewController
    {
        let container = CreateWalletContainer(handler: handler)
        return container.makeCreateWalletViewController()
    }
    
    func makeRestoreWalletViewController() -> RestoreWalletViewController
    {
        let container = RestoreWalletContainer(handler: handler)
        return container.makeRestoreWalletViewController()
    }
}

extension CreateOrRestoreWalletContainer: CreateOrRestoreWalletScenesFactory {}
