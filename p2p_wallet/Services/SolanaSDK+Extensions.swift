//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

extension SolanaSDK {
    static let shared = SolanaSDK(accountStorage: KeychainStorage.shared)
}
