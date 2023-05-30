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
                .fixedForStableCoin(tokenMint: token.address, fiat: fiat)
        } else {
            let result = try await api.getCurrentPrices(coins: [token], toFiat: fiat)

            let currentPrice: CurrentPrice = (result.values.first ?? nil)
                ?? CurrentPrice(value: 0.0)

            cache.insert(currentPrice, forKey: primaryKey(token.address, fiat))

            return currentPrice
                .fixedForStableCoin(tokenMint: token.address, fiat: fiat)
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
                .fixedForStableCoin(fiat: fiat)
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
                .fixedForStableCoin(fiat: fiat)
        }
    }

    /// Return all requested prices for token from cache. Return nil if one of them is missing
    func getPricesFromCache(tokens: [Token], fiat: String) -> [Token: CurrentPrice?]? {
        var result: [Token: CurrentPrice?] = [:]

        for token in tokens {
            if let value = getPriceFromCache(token: token, fiat: fiat) {
                result[token] = value
                    .fixedForStableCoin(tokenMint: token.address, fiat: fiat)
            } else {
                return nil
            }
        }

        return result
    }
    
    /// Return current cached price of a token
    public func getPriceFromCache(token: Token, fiat: String) -> CurrentPrice? {
        cache.value(forKey: primaryKey(token.address, fiat))
    }

    /// Helper method for extracing cache key.
    internal func primaryKey(_ mint: String, _ fiat: String) -> String {
        "\(mint)-\(fiat)"
    }
}

// MARK: - Stable coin price adjusting

private extension Dictionary where Key == Token, Value == Optional<CurrentPrice> {
    func fixedForStableCoin(fiat: String) -> Self {
        var adjustedSelf = self
        for price in self {
            adjustedSelf[price.key] = price.value?.fixedForStableCoin(tokenMint: price.key.address, fiat: fiat)
        }
        return adjustedSelf
    }
}

private extension CurrentPrice {
    /// Adjust prices for stable coin (usdc, usdt) make it equal to 1 if not depegged
    func fixedForStableCoin(tokenMint: String, fiat: String) -> Self {
        // assertion
        guard fiat.uppercased() == "USD", // current fiat is USD
              let value, // current price is not nil
              [Token.usdc.address, Token.usdt.address].contains(tokenMint), // token is usdc, usdt
              (abs(value - 1.0) * 100).rounded(to: 1) <= 2 // usdc, usdt wasn't depegged greater than 2%
        else {
            // otherwise return current value
            return self
        }
        
        // modify prices for usdc to usdt to make it equal to 1 USD
        return CurrentPrice(value: 1.0, change24h: change24h)
    }
}

private extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = Double.pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
