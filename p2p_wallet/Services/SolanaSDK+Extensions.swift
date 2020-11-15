//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import RxSwift

extension SolanaSDK {
    #if DEBUG
    static let cluster = "mainnet-beta"
    static let endpoint = "https://api.\(cluster).solana.com"
    #else
    static let cluster = "mainnet-beta"
    static let endpoint = "https://api.\(cluster).solana.com"
    #endif
    static let shared = SolanaSDK(endpoint: endpoint, accountStorage: KeychainStorage.shared)
}
