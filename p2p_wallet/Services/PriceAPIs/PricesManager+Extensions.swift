//
//  PricesManager+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

extension PricesManager {
    static let shared = PricesManager(fetcher: CryptoComparePricesFetcher(), refreshAfter: 10 * 1000) // 10minutes
}
