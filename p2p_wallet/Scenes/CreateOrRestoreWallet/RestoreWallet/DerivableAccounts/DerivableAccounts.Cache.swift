//
//  DerivableAccounts.Cache.swift
//  p2p_wallet
//
//  Created by Chung Tran on 31/05/2022.
//

import Foundation

extension DerivableAccounts {
    actor Cache {
        var balanceCache = [String: Double]() // PublicKey: Balance
        var solPriceCache: Double?

        func save(account: String, amount: Double) {
            balanceCache[account] = amount
        }

        func save(solPrice: Double) {
            solPriceCache = solPrice
        }
    }
}
