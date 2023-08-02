import BigDecimal
import Cache
import Combine
import Foundation
import KeyAppKitCore
import SolanaSwift

public struct PriceServiceOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let actualPrice = PriceServiceOptions(rawValue: 1 << 0)
}

/// Abstract class for getting exchange rate between token and fiat for any token.
public protocol PriceService: AnyObject {
    func getPrice(
        token: AnyToken,
        fiat: String,
        options: PriceServiceOptions
    ) async throws -> TokenPrice?

    func getPrices(
        tokens: [AnyToken],
        fiat: String,
        options: PriceServiceOptions
    ) async throws -> [SomeToken: TokenPrice]

    /// Emit request event to fetch new price.
    var onChangePublisher: AnyPublisher<Void, Never> { get }

    /// Clear cache.
    func clear() async throws
}

public extension PriceService {
    func getPrice(
        token: AnyToken,
        fiat: String
    ) async throws -> TokenPrice? {
        try await getPrice(token: token, fiat: fiat, options: [])
    }

    func getPrices(
        tokens: [AnyToken],
        fiat: String
    ) async throws -> [SomeToken: TokenPrice] {
        try await getPrices(tokens: tokens, fiat: fiat, options: [])
    }
}

/// This class service allow client to get exchange rate between token and fiat.
///
/// Each rate has 15 minutes lifetime. When the lifetime is expired, the new rate will be requested.
public class PriceServiceImpl: PriceService {
    /// Provider
    let api: KeyAppTokenProvider
    let errorObserver: ErrorObserver

    /// Data structure for caching
    enum TokenPriceRecord: Codable, Hashable {
        case requested(TokenPrice?)
    }

    /// Cache manager.
    let database: LifetimeDatabase<String, TokenPriceRecord>

    /// The timer synchronisation
    let timerPublisher: Timer.TimerPublisher = .init(interval: 60, runLoop: .main, mode: .default)

    ///
    let triggerPublisher: PassthroughSubject<Void, Never> = .init()

    public var onChangePublisher: AnyPublisher<Void, Never> {
        Publishers
            .Merge(
                timerPublisher
                    .autoconnect()
                    .map { _ in }
                    .eraseToAnyPublisher(),
                triggerPublisher
                    .eraseToAnyPublisher()
            )
            .eraseToAnyPublisher()
    }

    public init(api: KeyAppTokenProvider, errorObserver: ErrorObserver, lifetime: TimeInterval = 60 * 5) {
        self.api = api
        self.errorObserver = errorObserver
        database = .init(
            filePath: "token-price",
            storage: ApplicationFileStorage(),
            autoFlush: false,
            defaultLifetime: lifetime
        )
    }

    public func getPrices(
        tokens: [AnyToken], fiat: String,
        options: PriceServiceOptions
    ) async throws -> [SomeToken: TokenPrice] {
        let fiat = fiat.lowercased()
        var shouldSynchronise = false

        defer {
            if shouldSynchronise {
                triggerPublisher.send()
            }
        }

        if tokens.isEmpty {
            return [:]
        }

        var result: [SomeToken: TokenPriceRecord] = [:]

        // Get value from local storage
        for token in tokens {
            result[token.asSomeToken] = try? await database.read(for: token.id)
        }

        // Filter missing token price
        var missingPriceTokenMints: [AnyToken] = []
        for token in tokens {
            let token = token.asSomeToken

            if options.contains(.actualPrice) {
                // Fetch all prices when actual price is requested.
                missingPriceTokenMints.append(token)
            } else {
                // Fetch only price, that does not exists in cache.
                if result[token] == nil {
                    missingPriceTokenMints.append(token)
                }
            }
        }

        if !missingPriceTokenMints.isEmpty {
            // Request missing prices
            let newPrices = try await fetchTokenPrice(tokens: missingPriceTokenMints, fiat: fiat)

            // Process missing token prices
            for token in missingPriceTokenMints {
                let token = token.asSomeToken

                let price = newPrices[token]

                if let price {
                    let record = TokenPriceRecord.requested(price)

                    result[token] = record
                    try? await database.write(for: token.id, value: record)
                } else {
                    let record = TokenPriceRecord.requested(nil)

                    result[token] = record
                    try? await database.write(for: token.id, value: record)
                }
            }

            shouldSynchronise = true
            try? await database.flush()
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

    public func getPrice(token: AnyToken, fiat: String, options: PriceServiceOptions) async throws -> TokenPrice? {
        let result = try await getPrices(tokens: [token], fiat: fiat, options: options)
        return result.values.first ?? nil
    }

    internal func fetchTokenPrice(tokens: [AnyToken], fiat: String) async throws -> [SomeToken: TokenPrice] {
        var result: [SomeToken: TokenPrice] = [:]

        // Request missing token price
        let query: [KeyAppTokenProviderData.TokenQuery] = Dictionary(
            grouping: tokens,
            by: \.network
        ).map { (network: TokenNetwork, tokens: [AnyToken]) in
            let addresses = tokens.map(\.addressPriceMapping).unique

            return KeyAppTokenProviderData.TokenQuery(chainId: network.rawValue, addresses: addresses)
        }

        let newPrices = try await api.getTokensPrice(
            KeyAppTokenProviderData.Params(query: query)
        )

        for chain in newPrices {
            for tokenData in chain.data {
                // Token should be from requested list
                let token = tokens.first { token in token.addressPriceMapping == tokenData.address }
                guard let token = token?.asSomeToken else {
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
                        result[token] = price
                    } catch {
                        // Parsing error
                        result[token] = nil
                        errorObserver.handleError(error)
                    }
                } else {
                    // No price, we will not request it again.
                    result[token] = nil
                }
            }
        }

        // Transform values of TokenPriceRecord? to TokenPrice?
        return result
    }

    func parseTokenPrice(token: SomeToken, value: String, fiat: String) throws -> TokenPrice {
        var parsedValue = try BigDecimal(fromString: value)

        /// Adjust prices for stable coin (usdc, usdt) make it equal to 1 if not depegged more than 2%
        if
            case let .contract(address) = token.primaryKey,
            [PublicKey.usdcMint.base58EncodedString, PublicKey.usdtMint.base58EncodedString].contains(address),
            token.network == .solana,
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

    public func clear() async throws {
        try await database.clear()
    }
}

internal extension AnyToken {
    var addressPriceMapping: String {
        switch network {
        case .solana:
            switch primaryKey {
            case .native:
                return "native"
            case let .contract(address):
                return address
            }

        case .ethereum:
            switch primaryKey {
            case .native:
                return "native"
            case let .contract(address):
                return address
            }
        }
    }
}