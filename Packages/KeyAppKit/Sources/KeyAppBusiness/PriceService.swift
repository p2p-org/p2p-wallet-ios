//
//  NewPriceService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.03.2023.
//

import Cache
import Foundation
import SolanaPricesAPIs
import SolanaSwift

/// This class service allow client to get exchange rate between token and fiat.
///
/// Each rate has 15 minutes lifetime. When the lifetime is expired, the new rate will be requested.
public class PriceService {
    /// Provider.
    internal let api: SolanaPricesAPI

    /// Cache manager.
    internal let cache: LongTermCache<String, CurrentPrice>

    public init(api: SolanaPricesAPI, lifetime: TimeInterval = 60 * 15) {
        self.api = api
        self.cache = LongTermCache(entryLifetime: lifetime, maximumEntryCount: 999)
    }

    /// Get exchange rate for solana token.
    public func getPrice(token: Token, fiat: String) async throws -> CurrentPrice? {
        guard let coingeckoId = token.extensions?.coingeckoId else { return nil }

        if let cachedValue = cache.value(forKey: primaryKey(coingeckoId, fiat)) {
            return cachedValue
        } else {
            let result = try await api.getCurrentPrices(coins: [token], toFiat: fiat)

            if let result: CurrentPrice = result.values.first ?? nil {
                cache.insert(result, forKey: primaryKey(coingeckoId, fiat))
                return result
            } else {
                return nil
            }
        }
    }

    /// Batch request exchange rate for solana tokens
    // TODO: Optimize batch requesting
    public func getPrices(tokens: [Token], fiat: String) async throws -> [Token: CurrentPrice?] {
        if let cachedResult = getPricesFromCache(tokens: tokens, fiat: fiat) {
            return cachedResult
        } else {
            let prices = try await api.getCurrentPrices(coins: tokens, toFiat: fiat)

            for record in prices {
                if
                    let coingeckoId = record.key.extensions?.coingeckoId,
                    let value = record.value
                {
                    cache.insert(value, forKey: primaryKey(coingeckoId, fiat))
                }
            }

            return prices
        }
    }

    /// Return all requested prices for token from cache. Return nil if one of them is missing
    internal func getPricesFromCache(tokens: [Token], fiat: String) -> [Token: CurrentPrice?]? {
        var result: [Token: CurrentPrice?] = [:]

        for token in tokens {
            if
                let coingeckoId = token.extensions?.coingeckoId,
                let value = cache.value(forKey: primaryKey(coingeckoId, fiat))
            {
                result[token] = value
            } else {
                return nil
            }
        }

        return result
    }

    /// Helper method for extracing cache key.
    internal func primaryKey(_ id: String, _ fiat: String) -> String {
        "\(id)-\(fiat)"
    }
}
