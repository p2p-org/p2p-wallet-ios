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
    static let network = "mainnet-beta"
    static let endpoint = "https://api.\(network).solana.com"
    #else
    static let network = "mainnet-beta"
    static let endpoint = "https://api.\(network).solana.com"
    #endif
    static let shared = SolanaSDK(endpoint: endpoint, accountStorage: KeychainStorage.shared)
}

extension String: ListItemType {
    static func placeholder(at index: Int) -> String {
        "\(index)"
    }
}
