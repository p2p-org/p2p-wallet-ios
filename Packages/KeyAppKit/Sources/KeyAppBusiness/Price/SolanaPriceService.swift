//
//  NewPriceService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.03.2023.
//

import Cache
import Foundation
import KeyAppKitCore
import SolanaPricesAPIs
import SolanaSwift

/// This class service allow client to get exchange rate between token and fiat.
///
/// Each rate has 15 minutes lifetime. When the lifetime is expired, the new rate will be requested.
public class SolanaPriceService {
    /// Provider.
    internal let api: SolanaPricesAPI

    /// Cache manager.
    internal let cache: LongTermCache<String, CurrentPrice>

    public init(api: SolanaPricesAPI, lifetime: TimeInterval = 60 * 15) {
        self.api = api
        cache = LongTermCache(entryLifetime: lifetime, maximumEntryCount: 999)
    }

    /// Get exchange rate for solana token.
    public func getPrice(token: Token, fiat: String) async throws -> CurrentPrice {
        if let cachedValue = cache.value(forKey: primaryKey(token.address, fiat)) {
            return cachedValue
        } else {
            let result = try await api.getCurrentPrices(coins: [token], toFiat: fiat)

            let currentPrice: CurrentPrice = (result.values.first ?? nil)
                ?? CurrentPrice(value: 0.0)

            cache.insert(currentPrice, forKey: primaryKey(token.address, fiat))

            return currentPrice
        }
    }

    /// Batch request exchange rate for solana tokens
    // TODO: Optimize batch requesting
    public func getPrices(tokens: [Token], fiat: String) async throws -> [Token: CurrentPrice?] {
        guard !tokens.isEmpty else {
            return [:]
        }

        if let cachedResult = getPricesFromCache(tokens: tokens, fiat: fiat) {
            return cachedResult
        } else {
            let prices = try await api.getCurrentPrices(coins: tokens, toFiat: fiat)

            for token in tokens {
                let currentPrice: CurrentPrice = (prices[token] ?? nil)
                    ?? CurrentPrice(value: 0.0)

                cache.insert(
                    currentPrice,
                    forKey: primaryKey(token.address, fiat)
                )
            }
            for record in prices {
                cache.insert(
                    record.value ?? .init(value: 0.0),
                    forKey: primaryKey(record.key.address, fiat)
                )
            }

            return prices
        }
    }

    /// Return all requested prices for token from cache. Return nil if one of them is missing
    internal func getPricesFromCache(tokens: [Token], fiat: String) -> [Token: CurrentPrice?]? {
        var result: [Token: CurrentPrice?] = [:]

        for token in tokens {
            if let value = cache.value(forKey: primaryKey(token.address, fiat)) {
                result[token] = value
            } else {
                return nil
            }
        }

        return result
    }

    /// Helper method for extracing cache key.
    internal func primaryKey(_ mint: String, _ fiat: String) -> String {
        "\(mint)-\(fiat)"
    }
}
