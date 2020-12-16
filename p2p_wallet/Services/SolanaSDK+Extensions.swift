//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import RxSwift

extension SolanaSDK {
    enum Network: String, DefaultsSerializable {
        case devnet
        case testnet
        case mainnetBeta = "mainnet-beta"
        
        var cluster: String {rawValue}
        
        var endpoint: String {
            var string = cluster + ".solana.com"
            if self == .mainnetBeta { string = "api." + string }
            return "https://\(string)"
        }
    }
    
    static var shared = SolanaSDK(endpoint: Defaults.network.endpoint, accountStorage: AccountStorage.shared)
}

extension String: ListItemType {
    static func placeholder(at index: Int) -> String {
        "\(index)"
    }
    var id: String {self}
}
