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
    
    // longlived dependency
    let viewModel: CreateWalletViewModel
    
    init(
        accountStorage: KeychainAccountStorage,
        handler: CreateOrRestoreWalletHandler
    ) {
        self.viewModel = CreateWalletViewModel(handler: handler)
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
    
    func makeCreatePhrasesVC() -> CreateSecurityKeysViewController {
        CreateSecurityKeysViewController(viewModel: CreateSecurityKeysViewModel())
    }
    
    func makeCreatePhrasesVC(createWalletViewModel: CreateWalletViewModel) -> CreatePhrasesVC {
        CreatePhrasesVC(accountStorage: accountStorage, createWalletViewModel: viewModel)
    }
}

extension CreateWalletContainer: CreateWalletScenesFactory {}
