//
//  Account.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import Foundation

struct Account: Codable, Hashable {
    init(phrase: String, derivablePath: SolanaSDK.DerivablePath?) {
        self.name = nil // TODO: - Name service
        self.phrase = phrase
        self.derivablePath = derivablePath ?? .default
    }
    
    let name: String?
    let phrase: String
    let derivablePath: SolanaSDK.DerivablePath
}
