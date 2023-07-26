import Foundation
import KeyAppKitCore

public protocol KeyAppTokenProvider {
    /// Get token metadata by query
    func getTokensInfo(_ args: KeyAppTokenProviderData.Params<KeyAppTokenProviderData.TokenQuery>) async throws
        -> [KeyAppTokenProviderData.TokenResult<KeyAppTokenProviderData.Token>]

    /// Get token price by query
    func getTokensPrice(_ args: KeyAppTokenProviderData.Params<KeyAppTokenProviderData.TokenQuery>) async throws
        -> [KeyAppTokenProviderData.TokenResult<KeyAppTokenProviderData.Price>]

    /// Get all solana tokens
    func getSolanaTokens(modifiedSince: Date?) async throws -> KeyAppTokenProviderData.AllSolanaTokensResult
}

public class KeyAppTokenHttpProvider: KeyAppTokenProvider {
    public let client: HTTPJSONRPCCLient

    public init(client: HTTPJSONRPCCLient) {
        self.client = client
    }

    public func getTokensInfo(_ args: KeyAppTokenProviderData.Params<KeyAppTokenProviderData.TokenQuery>) async throws
    -> [KeyAppTokenProviderData.TokenResult<KeyAppTokenProviderData.Token>] {
        try await client.call(method: "get_tokens_info", params: args)
    }

    public func getTokensPrice(_ args: KeyAppTokenProviderData.Params<KeyAppTokenProviderData.TokenQuery>) async throws
    -> [KeyAppTokenProviderData.TokenResult<KeyAppTokenProviderData.Price>] {
        try await client.call(method: "get_tokens_price", params: args)
    }

    public func getSolanaTokens(modifiedSince: Date?) async throws -> KeyAppTokenProviderData.AllSolanaTokensResult {
        guard let url = URL(string: "\(client.endpoint)/get_all_tokens_info") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringCacheData
        request.httpMethod = "GET"
        request.setValue("gzip", forHTTPHeaderField: "accept-encoding")

        if let modifiedSince {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss zzz"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
            let formattedDate = dateFormatter.string(from: modifiedSince)

            request.setValue(formattedDate, forHTTPHeaderField: "if-modified-since")
        }

        let (data, response) = try await client.urlSession.data(for: request)
        
        if
            let response = response as? HTTPURLResponse,
            response.statusCode == 304
        {
            return .noChanges
        }

        let parsedData = try JSONDecoder().decode(KeyAppTokenProviderData.AllSolanaTokensResult.Result.self, from: data)
        return .result(parsedData)
    }
}
