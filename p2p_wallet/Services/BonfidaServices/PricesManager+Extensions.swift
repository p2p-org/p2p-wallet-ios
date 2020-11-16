//
//  PricesManager+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

extension PricesManager {
    static let bonfida: PricesManager = {
        var fetcher = BonfidaPricesFetcher()
        fetcher.pairs = SolanaSDK.Token.getSupportedTokens(network: SolanaSDK.network)?.map {$0.symbol}.map {(from: $0, to: "USDT")} ?? []
        let manager = PricesManager(fetcher: fetcher)
        return manager
    }()
}
