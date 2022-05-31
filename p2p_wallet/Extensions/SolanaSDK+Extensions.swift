//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/10/2021.
//

import Foundation
import SolanaSwift

extension SolanaSDK.APIEndPoint {
    static var definedEndpoints: [Self] {
        var endpoints = defaultEndpoints
        endpoints.insert(
            .init(address: "https://p2p.rpcpool.com", network: .mainnetBeta,
                  additionalQuery: .secretConfig("RPCPOOL_API_KEY")),
            at: 0
        )
        #if !DEBUG
            endpoints.removeAll { $0.network == .testnet || $0.network == .devnet }
        #endif
        return endpoints
    }
}
