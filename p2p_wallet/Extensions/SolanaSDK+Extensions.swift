//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/10/2021.
//

import Foundation

extension SolanaSDK.APIEndPoint {
    static var definedEndpoints: [Self] {
        var endpoints = defaultEndpoints
        endpoints.insert(
            .init(address: "https://p2p.rpcpool.com", network: .mainnetBeta,
                  additionalQuery: .secretConfig("RPCPOOL_API_KEY")),
            at: 0
        )
        return endpoints
    }
}
