//
//  NewPriceService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.03.2023.
//

import BigDecimal
import Cache
import Foundation
import KeyAppKitCore
import SolanaSwift

/// Abstract class for getting exchange rate between token and fiat for any token.
public protocol PriceService {
    func getPrice(token: AnyToken, fiat: String) async throws -> TokenPrice?
    func getPrices(tokens: [AnyToken], fiat: String) async throws -> [SomeToken: TokenPrice]
}

/// This class service allow client to get exchange rate between token and fiat.
///
/// Each rate has 15 minutes lifetime. When the lifetime is expired, the new rate will be requested.
public class PriceServiceImpl: PriceService {
    /// Provider
    let api: KeyAppTokenProvider
    let errorObserver: ErrorObserver

    /// Data structure for caching
    enum TokenPriceRecord {
        case requested(TokenPrice?)
    }

    /// Cache manager.
    let cache: LongTermCache<String, TokenPriceRecord>

    public init(api: KeyAppTokenProvider, errorObserver: ErrorObserver, lifetime: TimeInterval = 60 * 15) {
        self.api = api
        self.errorObserver = errorObserver
        cache = LongTermCache(entryLifetime: lifetime, maximumEntryCount: 999)
    }

    public func getPrices(tokens: [AnyToken], fiat: String) async throws -> [SomeToken: TokenPrice] {
        if tokens.isEmpty {
            return [:]
        }

        var result: [SomeToken: TokenPriceRecord] = [:]

        // Get value from local storage
        for token in tokens {
            result[token.asSomeToken] = cache.value(forKey: token.id)
        }

        // Build requested token, that misses token price.
        var missingPriceTokenMints: [AnyToken] = []
        for token in tokens {
            let token = token.asSomeToken

            if result[token] == nil {
                missingPriceTokenMints.append(token)
            }
        }

        // Request missing token price
        let query: [KeyAppTokenProviderData.TokenQuery] = Dictionary(
            grouping: missingPriceTokenMints,
            by: \.network
        ).map { (network: TokenNetwork, tokens: [AnyToken]) in
            let addresses = tokens.map(\.addressPriceMapping)

            return KeyAppTokenProviderData.TokenQuery(chainId: network.rawValue, addresses: addresses)
        }

        let newPrices = try await api.getTokensPrice(
            KeyAppTokenProviderData.Params(query: query)
        )

        // Process new token prices
        for tokenData in newPrices.first?.data ?? [] {
            guard let token = tokens.first(where: { token in token.addressPriceMapping == tokenData.address })?
                .asSomeToken
            else {
                // Token should be from requested list
                continue
            }

            if
                let priceValueContainer = tokenData.price[fiat],
                let priceValue = priceValueContainer
            {
                do {
                    // Parse
                    let price = try parseTokenPrice(token: token, value: priceValue, fiat: fiat)

                    // Ok case
                    cache.insert(.requested(price), forKey: token.id)
                    result[token] = .requested(price)
                } catch {
                    // Parsing error
                    cache.removeValue(forKey: token.id)
                    result[token] = nil

                    errorObserver.handleError(error)
                }
            } else {
                // No price, we will not request it again.
                cache.insert(.requested(nil), forKey: token.id)
                result[token] = nil
            }
        }

        // Transform values of TokenPriceRecord? to TokenPrice?
        return result
            .compactMapValues { record in
                switch record {
                case let .requested(value):
                    return value
                }
            }
    }

    public func getPrice(token: AnyToken, fiat: String) async throws -> TokenPrice? {
        let result = try await getPrices(tokens: [token], fiat: fiat)
        return result.values.first ?? nil
    }

    func parseTokenPrice(token: SomeToken, value: String, fiat: String) throws -> TokenPrice {
        var parsedValue = try BigDecimal(fromString: value)

        /// Adjust prices for stable coin (usdc, usdt) make it equal to 1 if not depegged more than 2%
        if
            case let .contract(address) = token.primaryKey,
            [SolanaToken.usdc.address, SolanaToken.usdt.address].contains(address),
            token.network == .solana,
            fiat.uppercased() == "USD",
            (abs(parsedValue - 1.0) * 100) <= 2
        {
            parsedValue = 1.0
        }

        return TokenPrice(
            currencyCode: fiat,
            value: parsedValue,
            token: token
        )
    }
}

internal extension AnyToken {
    var addressPriceMapping: String {
        switch network {
        case .solana:
            switch primaryKey {
            case .native:
                return  SolanaToken.nativeSolana.address
            case let .contract(address):
                return address
            }

        case .ethereum:
            switch primaryKey {
            case .native:
                return "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
            case let .contract(address):
                return address
            }
        }
    }
}
