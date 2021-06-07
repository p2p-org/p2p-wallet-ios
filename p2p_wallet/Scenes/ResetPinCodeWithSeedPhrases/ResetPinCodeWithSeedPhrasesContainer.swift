//
//  ResetPinCodeWithSeedPhrasesContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation

class ResetPinCodeWithSeedPhrasesContainer {
    let accountStorage: KeychainAccountStorage
    lazy var viewModel = ResetPinCodeWithSeedPhrasesViewModel(accountStorage: accountStorage)
    
    init(
        accountStorage: KeychainAccountStorage
    ) {
        self.accountStorage = accountStorage
        
    }
    
    func makeResetPinCodeWithSeedPhrasesViewController() -> ResetPinCodeWithSeedPhrasesViewController
    {
        ResetPinCodeWithSeedPhrasesViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeEnterPhrasesVC() -> WLEnterPhrasesVC {
        WLEnterPhrasesVC(handler: viewModel)
    }
    
    func makeCreatePassCodeVC() -> CreatePassCodeVC {
        CreatePassCodeVC()
    }
}

extension ResetPinCodeWithSeedPhrasesContainer: ResetPinCodeWithSeedPhrasesScenesFactory
{}
