import Foundation
import KeyAppKitCore

public enum KeyAppTokenProviderData {
    public struct Params<T: Codable & Hashable>: Codable, Hashable {
        public let query: [T]
    }

    public struct TokenQuery: Codable, Hashable {
        public let chainId: String
        public let addresses: [String]

        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case addresses
        }
    }

    public struct TokenResult<Data: Codable & Hashable>: Codable, Hashable {
        public let chainId: String
        public let data: [Data]

        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case data
        }
    }

    public struct GetTokenInfoResult: Codable, Hashable {
        public let chainId: String
        public let data: [Token]

        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case data
        }
    }

    public struct Token: Codable, Hashable {
        public let address: String
        public let symbol: String
        public let name: String
        public let logoUrl: String?
        public let decimals: UInt8
        public let price: [String: String?]

        enum CodingKeys: String, CodingKey {
            case address
            case symbol
            case name
            case logoUrl = "logo_url"
            case decimals
            case price
        }
    }

    public struct Price: Codable, Hashable {
        public let address: String
        public let price: [String: String?]

        public init(address: String, price: [String: String?]) {
            self.address = address
            self.price = price
        }
    }

    public enum AllSolanaTokensResult: Hashable {
        case result(Result)
        case noChanges

        public struct Result: Codable, Hashable {
            public let timestamp: Date
            public let tokens: [SolanaToken]

            public init(from decoder: Decoder) throws {
                let container: KeyedDecodingContainer<KeyAppTokenProviderData.AllSolanaTokensResult.Result.CodingKeys> =
                    try decoder.container(keyedBy: KeyAppTokenProviderData.AllSolanaTokensResult.Result.CodingKeys.self)

                let timestampStr = try container.decode(
                    String.self,
                    forKey: KeyAppTokenProviderData.AllSolanaTokensResult.Result.CodingKeys.timestamp
                )

                let formatter = ISO8601DateFormatter()
                formatter.formatOptions.insert(.withFractionalSeconds)
                timestamp = (formatter.date(from: timestampStr) ?? Date()) + 1

                tokens = try container.decode(
                    [SolanaToken].self,
                    forKey: KeyAppTokenProviderData.AllSolanaTokensResult.Result.CodingKeys.tokens
                )
            }
        }
    }
}
