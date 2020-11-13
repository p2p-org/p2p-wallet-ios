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
    static let cluster = "devnet"
    #else
    static let cluster = "devnet"
    #endif
    static let endpoint = "https://\(cluster).solana.com"
    static let shared = SolanaSDK(endpoint: endpoint, accountStorage: KeychainStorage.shared)
}
