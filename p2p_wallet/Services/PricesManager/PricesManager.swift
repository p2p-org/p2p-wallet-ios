//
//  PricesManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

struct PricesManager {
    var fetcher: PricesFetcher
    var prices: BehaviorRelay<[Price]> {fetcher.prices}
    
    init(fetcher: PricesFetcher) {
        self.fetcher = fetcher
        self.fetcher.updatePriceForUSDType()
        self.fetcher.pairs = getPairs()
    }
    
    func getPairs() -> [PricesFetcher.Pair] {
        SolanaSDK.Token.getSupportedTokens(network: SolanaSDK.network)?.map {$0.symbol}.map {(from: $0, to: "USDT")}.filter {$0.from != "USDT" && $0.from != "USDC" && $0.from != "WUSDC"} ?? []
    }
}
