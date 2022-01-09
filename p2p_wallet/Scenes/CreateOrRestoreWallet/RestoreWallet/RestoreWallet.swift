//
//  RestoreWallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/09/2021.
//

import Foundation

enum RestoreWallet {
    enum NavigatableScene {
        case enterPhrases
        case restoreFromICloud
        case reserveName(owner: String)
        case derivableAccounts(phrases: [String])
    }
}
