//
//  PricesManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

class PricesManager {
    var fetcher: PricesFetcher
    var prices: BehaviorRelay<[Price]> {fetcher.prices}
    var refreshInterval: TimeInterval // Refresh
    
    private var timer: Timer?
    
    init(fetcher: PricesFetcher, refreshAfter seconds: TimeInterval = 30) {
        self.fetcher = fetcher
        self.fetcher.updatePriceForUSDType()
        self.refreshInterval = seconds
        
        self.fetcher.pairs = getPairs()
    }
    
    func startObserving() {
        PricesManager.bonfida.fetcher.fetchAll()
        timer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
    }
    
    func stopObserving() {
        timer?.invalidate()
    }
    
    func getPairs() -> [PricesFetcher.Pair] {
        SolanaSDK.Token.getSupportedTokens(network: SolanaSDK.network)?.map {$0.symbol}.map {(from: $0, to: "USDT")}.filter {$0.from != "USDT" && $0.from != "USDC" && $0.from != "WUSDC"} ?? []
    }
    
    @objc func refresh() {
        fetcher.fetchAll()
    }
    
    deinit {
        timer?.invalidate()
    }
}
