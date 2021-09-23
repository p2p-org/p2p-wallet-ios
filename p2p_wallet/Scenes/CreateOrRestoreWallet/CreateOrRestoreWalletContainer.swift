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
    @Injected private var accountStorage: KeychainAccountStorage
    let analyticsManager: AnalyticsManagerType
    
    // longlived dependency
    let viewModel: CreateOrRestoreWalletViewModel
    
    init(
        handler: CreateOrRestoreWalletHandler,
        analyticsManager: AnalyticsManagerType
    ) {
        self.viewModel = CreateOrRestoreWalletViewModel(analyticsManager: analyticsManager)
        self.handler = handler
        self.analyticsManager = analyticsManager
    }
    
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController {
        CreateOrRestoreWalletViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeCreateWalletViewController() -> CreateWalletViewController
    {
        let container = CreateWalletContainer(handler: handler, analyticsManager: analyticsManager)
        return container.makeCreateWalletViewController()
    }
    
    func makeRestoreWalletViewController() -> RestoreWalletViewController
    {
        let container = RestoreWalletContainer(handler: handler, analyticsManager: analyticsManager)
        return container.makeRestoreWalletViewController()
    }
}

extension CreateOrRestoreWalletContainer: CreateOrRestoreWalletScenesFactory {}
