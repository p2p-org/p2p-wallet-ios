//
//  PricesStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/11/2021.
//

import Foundation
import SolanaPricesAPIs

protocol PricesStorage {
    func retrievePrices() async -> TokenPriceMap
    func savePrices(_ prices: TokenPriceMap) async
}

actor UserDefaultsPricesStorage: PricesStorage {
    func retrievePrices() -> TokenPriceMap {
        var prices: TokenPriceMap = [:]
        let data = Defaults.prices
        if !data.isEmpty,
           let cachedPrices = try? PropertyListDecoder().decode(TokenPriceMap.self, from: data)
        {
            prices = cachedPrices
        }
        return prices
    }

    func savePrices(_ prices: TokenPriceMap) {
        guard let data = try? PropertyListEncoder().encode(prices) else { return }
        Defaults.prices = data
    }
}
