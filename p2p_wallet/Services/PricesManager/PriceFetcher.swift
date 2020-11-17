//
//  PriceFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

struct Price: Hashable {
    struct Change24h: Hashable {
        var value: Double?
        var percentage: Double?
    }
    
    let from: String
    var to: String = "USDT"
    var value: Double?
    var change24h: Change24h?
}

protocol PricesFetcher {
    typealias Pair = (from: String, to: String)
    var pairs: [Pair] {get set}
    var prices: BehaviorRelay<[Price]> {get}
    var disposeBag: DisposeBag {get}
    func fetch(pair: Pair) -> Single<Price>
    func fetchAll()
}

extension PricesFetcher {
    func updatePriceForUSDType() {
        updatePair((from: "USDT", to: "USDT"), newPrice: Price(from: "USDT", to: "USDT", value: 1, change24h: Price.Change24h(value: 0, percentage: 0)))
        updatePair((from: "USDC", to: "USDT"), newPrice: Price(from: "USDC", to: "USDT", value: 1, change24h: Price.Change24h(value: 0, percentage: 0)))
        updatePair((from: "WUSDC", to: "USDT"), newPrice: Price(from: "WUSDC", to: "USDT", value: 1, change24h: Price.Change24h(value: 0, percentage: 0)))
    }
    
    func updatePair(_ pair: Pair, newPrice: Price) {
        var prices = self.prices.value
        if let index = prices.firstIndex(where: {$0.from == pair.from && $0.to == pair.to})
        {
            var price = prices[index]
            price.value = newPrice.value
            price.change24h = newPrice.change24h
            prices[index] = price
            self.prices.accept(prices)
        } else {
            prices.append(newPrice)
        }
        self.prices.accept(prices)
    }
}
