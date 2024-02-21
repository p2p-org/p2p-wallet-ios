import Combine
import Foundation
import KeyAppKitCore

public class CoingeckoEthereumPriceService: PriceService {
    static let wETH = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

    /// Data structure for caching
    enum TokenPriceRecord: Codable, Hashable {
        case requested(TokenPrice?)
    }

    enum Error: Swift.Error {
        case invalidURL
    }

    let endpoint: String

    let database: LifetimeDatabase<String, TokenPriceRecord>

    public init(endpoint: String) {
        self.endpoint = endpoint
        database = .init(
            filePath: "ethereum-token-price",
            storage: ApplicationFileStorage(),
            autoFlush: false,
            defaultLifetime: 60 * 5
        )
    }

    public let onChangePublisher: AnyPublisher<Void, Never> = PassthroughSubject<Void, Never>().eraseToAnyPublisher()

    public func getPrice(token: AnyToken, fiat: String, options: PriceServiceOptions) async throws -> TokenPrice? {
        try await getPrices(tokens: [token], fiat: fiat, options: options).first?.value
    }

    public func getPrices(
        tokens: [AnyToken],
        fiat: String,
        options: PriceServiceOptions
    ) async throws -> [SomeToken: TokenPrice] {
        let fiat = fiat.lowercased()
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

    func fetchTokenPrice(tokens: [AnyToken], fiat: String) async throws -> [SomeToken: TokenPrice] {
        let contractAddresses = tokens.map(\.primaryKey).map { key in
            switch key {
            case .native:
                return Self.wETH
            case let .contract(address):
                return address
            }
        }
        .joined(separator: ",")

        guard let url =
            URL(
                string: "\(endpoint)/api/v3/simple/token_price/ethereum?contract_addresses=\(contractAddresses)&vs_currencies=\(fiat.lowercased())"
            )
        else {
            throw Error.invalidURL
        }

        let request = URLRequest(url: url)

        let (data, _) = try await URLSession.shared.data(for: request)
        let priceResult = try JSONDecoder().decode(
            [String: [String: Double]].self,
            from: data
        )

        var priceData: [SomeToken: TokenPrice] = [:]
        for token in tokens {
            let token = token.asSomeToken

            let value: Double?
            if token.primaryKey == .native {
                value = priceResult[Self.wETH]?[fiat]
            } else {
                value = priceResult[token.primaryKey.id]?[fiat]
            }

            if let value {
                priceData[token] = TokenPrice(currencyCode: fiat, value: .init(floatLiteral: value), token: token)
            } else {
                priceData[token] = TokenPrice(currencyCode: fiat, value: nil, token: token)
            }
        }

        return priceData
    }

    public func clear() async throws {}
}
