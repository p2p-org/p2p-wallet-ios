//
//  ResetPinCodeWithSeedPhrasesContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation

struct ResetPinCodeWithSeedPhrasesContainer {
    let viewModel = ResetPinCodeWithSeedPhrasesViewModel()
    
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
