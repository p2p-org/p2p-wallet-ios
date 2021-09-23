//
//  ResetPinCodeWithSeedPhrasesContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation

class ResetPinCodeWithSeedPhrasesContainer {
    lazy var viewModel = ResetPinCodeWithSeedPhrasesViewModel()
    
    func makeResetPinCodeWithSeedPhrasesViewController() -> ResetPinCodeWithSeedPhrasesViewController
    {
        ResetPinCodeWithSeedPhrasesViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeEnterPhrasesVC() -> ResetPinCodeWithSeedPhrasesEnterPhrasesVC {
        ResetPinCodeWithSeedPhrasesEnterPhrasesVC(handler: viewModel)
    }
    
    func makeCreatePassCodeVC() -> CreatePassCodeVC {
        CreatePassCodeVC()
    }
}

extension ResetPinCodeWithSeedPhrasesContainer: ResetPinCodeWithSeedPhrasesScenesFactory
{}
