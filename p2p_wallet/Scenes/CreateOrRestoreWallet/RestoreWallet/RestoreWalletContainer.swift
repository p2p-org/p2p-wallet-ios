//
//  RestoreWalletContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class RestoreWalletContainer {
    // from parent
    let handler: CreateOrRestoreWalletHandler
    let accountStorage: KeychainAccountStorage
    
    // longlived dependency
    let viewModel: RestoreWalletViewModel
    
    init(
        accountStorage: KeychainAccountStorage,
        handler: CreateOrRestoreWalletHandler
    ) {
        self.viewModel = RestoreWalletViewModel(accountStorage: accountStorage, handler: handler)
        self.accountStorage = accountStorage
        self.handler = handler
    }
    
    func makeRestoreWalletViewController() -> RestoreWalletViewController
    {
        RestoreWalletViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeEnterPhrasesVC() -> EnterPhrasesVC {
        EnterPhrasesVC(restoreWalletViewModel: viewModel)
    }
    
    func makeWelcomeBackVC(phrases: [String]) -> WelcomeBackVC {
        WelcomeBackVC(phrases: phrases, accountStorage: accountStorage, restoreWalletViewModel: viewModel)
    }
}

extension RestoreWalletContainer: RestoreWalletScenesFactory {}
