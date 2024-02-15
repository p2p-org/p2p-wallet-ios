import BigDecimal
import Combine
import Foundation
import KeyAppKitCore
import KeyAppNetworking
import SolanaSwift
import TokenService

public protocol JupiterPriceService: AnyObject {
    /// Get actual price in specific fiat for token.
    func getPrice(
        token: AnyToken,
        fiat: String
    ) async throws -> TokenPrice?

    /// Get actual prices in specific fiat for token.
    func getPrices(
        tokens: [AnyToken],
        fiat: String
    ) async throws -> [SomeToken: TokenPrice]

    /// Emit request event to fetch new price.
    var onChangePublisher: AnyPublisher<Void, Never> { get }
}

public final class JupiterPriceServiceImpl: JupiterPriceService {
    // MARK: - Inner structure

    /// Data structure for caching
    enum TokenPriceRecord: Codable, Hashable {
        case requested(TokenPrice?)
    }

    // MARK: - Providers

    let client: HTTPClient

    // MARK: - Event stream

    /// The timer synchronisation
    let timerPublisher: Timer.TimerPublisher = .init(interval: 60, runLoop: .main, mode: .default)

    public var onChangePublisher: AnyPublisher<Void, Never> {
        timerPublisher
            .autoconnect()
            .map { _ in }
            .eraseToAnyPublisher()
    }

    // MARK: - Constructor

    public init(client: HTTPClient) {
        self.client = client
    }

    // MARK: - Methods

    public func getPrices(
        tokens: [AnyToken], fiat: String
    ) async throws -> [SomeToken: TokenPrice] {
        let fiat = fiat.lowercased()

        if tokens.isEmpty {
            return [:]
        }

        var result: [SomeToken: TokenPriceRecord] = [:]

        // Filter missing token price
        let missingPriceTokenMints: [AnyToken] = tokens.map(\.asSomeToken)

        // Request missing prices
        let newPrices = try await fetchTokenPrice(tokens: missingPriceTokenMints, fiat: fiat)

        // Process missing token prices
        for token in missingPriceTokenMints {
            let token = token.asSomeToken

            if let price = newPrices[token] {
                let record = TokenPriceRecord.requested(price)
                result[token] = record
            } else {
                let record = TokenPriceRecord.requested(nil)
                result[token] = record
            }
        }

        // Transform values of TokenPriceRecord? to TokenPrice?
        let priceResult = result
            .compactMapValues { record in
                switch record {
                case let .requested(value):
                    return value
                }
            }

        return priceResult
    }

    public func getPrice(token: AnyToken, fiat: String) async throws -> TokenPrice? {
        let result = try await getPrices(tokens: [token], fiat: fiat)
        return result.values.first ?? nil
    }

    /// Method for fetching price from server
    private func fetchTokenPrice(tokens: [AnyToken], fiat: String) async throws -> [SomeToken: TokenPrice] {
        var result: [SomeToken: TokenPrice] = [:]

        // Request token price
        let query = tokens.map(\.jupiterAddressMaping).joined(separator: ",")

        // Fetch
        let newPrices = try await getTokensPrice(ids: query).data
        for tokenData in newPrices {
            // Token should be from requested list
            let token = tokens.first { token in token.jupiterAddressMaping == tokenData.key }
            guard let token = token?.asSomeToken else { continue }

            // Parse
            let price = parseTokenPrice(token: token, value: tokenData.value.usdPrice, fiat: fiat)
            result[token] = price
        }

        // Transform values of TokenPriceRecord? to TokenPrice?
        return result
    }

    private func getTokensPrice(ids: String) async throws -> JupiterPricesRootResponse {
        try await client.request(
            endpoint: DefaultHTTPEndpoint(
                baseURL: "https://price.jup.ag/",
                path: "v4/price?ids=\(ids)",
                method: .get,
                header: [:]
            ),
            responseModel: JupiterPricesRootResponse.self
        )
    }

    private func parseTokenPrice(token: SomeToken, value: Double, fiat: String) -> TokenPrice {
        TokenPrice(
            currencyCode: fiat,
            value: BigDecimal(floatLiteral: value),
            token: token
        )
    }
}

private struct JupiterPricesRootResponse: Decodable {
    let data: [String: JupiterPricesResponse]
}

private struct JupiterPricesResponse: Decodable {
    let mintAddress: String
    let tokenSymbol: String
    let usdPrice: Double // 1 unit of the token worth in USDC

    enum CodingKeys: String, CodingKey {
        case mintAddress = "id"
        case tokenSymbol = "mintSymbol"
        case usdPrice = "price"
    }
}
