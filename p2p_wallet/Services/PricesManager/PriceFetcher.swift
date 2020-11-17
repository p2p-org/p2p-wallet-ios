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
    let from: String
    var to: String = "USDT"
    var value: Double?
}

protocol PricesFetcher {
    typealias Pair = (from: String, to: String)
    var pairs: [Pair] {get set}
    var prices: BehaviorRelay<[Price]> {get}
    var disposeBag: DisposeBag {get}
    func fetch(pair: Pair) -> Single<Double>
    func fetchAll()
}

extension PricesFetcher {
    func updatePriceForUSDType() {
        updatePair((from: "USDT", to: "USDT"), value: 1)
        updatePair((from: "USDC", to: "USDT"), value: 1)
        updatePair((from: "WUSDC", to: "USDT"), value: 1)
    }
    
    func updatePair(_ pair: Pair, value: Double) {
        var prices = self.prices.value
        if let index = prices.firstIndex(where: {$0.from == pair.from && $0.to == pair.to})
        {
            var price = prices[index]
            price.value = value
            prices[index] = price
            self.prices.accept(prices)
        } else {
            prices.append(Price(from: pair.from, to: pair.to, value: value))
        }
        self.prices.accept(prices)
    }
}
