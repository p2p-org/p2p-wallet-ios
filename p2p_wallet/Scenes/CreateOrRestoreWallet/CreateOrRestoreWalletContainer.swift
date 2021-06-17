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
    let analyticsManager: AnalyticsManagerType
    
    // longlived dependency
    let viewModel: CreateOrRestoreWalletViewModel
    
    init(
        accountStorage: KeychainAccountStorage,
        handler: CreateOrRestoreWalletHandler,
        analyticsManager: AnalyticsManagerType
    ) {
        self.viewModel = CreateOrRestoreWalletViewModel(analyticsManager: analyticsManager)
        self.accountStorage = accountStorage
        self.handler = handler
        self.analyticsManager = analyticsManager
    }
    
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController {
        CreateOrRestoreWalletViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeCreateWalletViewController() -> CreateWalletViewController
    {
        let container = CreateWalletContainer(accountStorage: accountStorage, handler: handler, analyticsManager: analyticsManager)
        return container.makeCreateWalletViewController()
    }
    
    func makeRestoreWalletViewController() -> RestoreWalletViewController
    {
        let container = RestoreWalletContainer(accountStorage: accountStorage, handler: handler, analyticsManager: analyticsManager)
        return container.makeRestoreWalletViewController()
    }
}

extension CreateOrRestoreWalletContainer: CreateOrRestoreWalletScenesFactory {}
