//
//  CreateWallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/09/2021.
//

import Foundation

enum CreateWallet {
    enum NavigatableScene {
        case explanation
        case createPhrases
        case verifyPhrase(_ phrase: [String])
        case reserveName(owner: String)
        case dismiss
        case back
    }
}
