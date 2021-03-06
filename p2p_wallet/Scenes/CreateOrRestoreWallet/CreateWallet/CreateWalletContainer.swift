//
//  CreateWalletContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class CreateWalletContainer {
    // from parent
    let handler: CreateOrRestoreWalletHandler
    let accountStorage: KeychainAccountStorage
    let analyticsManager: AnalyticsManagerType
    
    // longlived dependency
    let viewModel: CreateWalletViewModel
    
    init(
        accountStorage: KeychainAccountStorage,
        handler: CreateOrRestoreWalletHandler,
        analyticsManager: AnalyticsManagerType
    ) {
        self.analyticsManager = analyticsManager
        self.viewModel = CreateWalletViewModel(handler: handler, analyticsManager: analyticsManager)
        self.accountStorage = accountStorage
        self.handler = handler
    }
    
    func makeCreateWalletViewController() -> CreateWalletViewController
    {
        CreateWalletViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeTermsAndConditionsVC() -> TermsAndConditionsVC {
        TermsAndConditionsVC(createWalletViewModel: viewModel)
    }
    
    func makeCreateSecurityKeysViewController() -> CreateSecurityKeysViewController {
        let viewModel = CreateSecurityKeysViewModel(accountStorage: accountStorage, createWalletViewModel: self.viewModel, analyticsManager: analyticsManager)
        return CreateSecurityKeysViewController(viewModel: viewModel)
    }
}

extension CreateWalletContainer: CreateWalletScenesFactory {}
