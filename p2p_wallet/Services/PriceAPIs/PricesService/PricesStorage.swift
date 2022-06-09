//
//  PricesStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/11/2021.
//

import Foundation
import SolanaPricesAPIs

protocol PricesStorage {
    func retrievePrices() -> [String: CurrentPrice]
    func savePrices(_ prices: [String: CurrentPrice])
}

class UserDefaultsPricesStorage: PricesStorage {
    func retrievePrices() -> [String: CurrentPrice] {
        var prices = [String: CurrentPrice]()
        let data = Defaults.prices
        if !data.isEmpty,
           let cachedPrices = try? PropertyListDecoder().decode([String: CurrentPrice].self, from: data)
        {
            prices = cachedPrices
        }
        return prices
    }

    func savePrices(_ prices: [String: CurrentPrice]) {
        guard let data = try? PropertyListEncoder().encode(prices) else { return }
        Defaults.prices = data
    }
}
