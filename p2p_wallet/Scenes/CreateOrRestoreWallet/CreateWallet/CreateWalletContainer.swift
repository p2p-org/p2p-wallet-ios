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
    @Injected private var accountStorage: KeychainAccountStorage
    @Injected private var analyticsManager: AnalyticsManagerType
    
    // longlived dependency
    let viewModel: CreateWalletViewModel
    
    init(
        handler: CreateOrRestoreWalletHandler
    ) {
        self.viewModel = CreateWalletViewModel(handler: handler)
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
        let viewModel = CreateSecurityKeysViewModel(createWalletViewModel: self.viewModel)
        return CreateSecurityKeysViewController(viewModel: viewModel)
    }
}

extension CreateWalletContainer: CreateWalletScenesFactory {}
