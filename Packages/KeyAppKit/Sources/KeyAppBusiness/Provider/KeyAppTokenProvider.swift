//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.07.2023.
//

import Foundation
import KeyAppKitCore

public enum KeyAppToken {
    public struct Params<T: Codable & Hashable>: Codable, Hashable {
        public let query: [T]
    }

    public struct GetToken: Codable, Hashable {
        public let chainId: String
        public let addresses: [String]

        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case addresses
        }
    }

    public struct GetPriceInfoResult: Codable, Hashable {
        public let chainId: String
        public let data: [TokenData]

        public struct TokenData: Codable, Hashable {
            public let address: String
            public let price: [String: String?]
            
            public init(address: String, price: [String: String?]) {
                self.address = address
                self.price = price
            }

            public init(from decoder: Decoder) throws {
                let container: KeyedDecodingContainer<KeyAppToken.GetPriceInfoResult.TokenData.CodingKeys> = try decoder
                    .container(keyedBy: KeyAppToken.GetPriceInfoResult.TokenData.CodingKeys.self)
                address = try container.decode(
                    String.self,
                    forKey: KeyAppToken.GetPriceInfoResult.TokenData.CodingKeys.address
                )
                price = try container.decode(
                    [String: String?].self,
                    forKey: KeyAppToken.GetPriceInfoResult.TokenData.CodingKeys.price
                )
            }
        }

        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case data
        }
    }

    public struct GetTokenInfoResult: Codable, Hashable {
        public let chainId: String
        public let data: [TokenData]

        public struct TokenData: Codable, Hashable {
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

        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case data
        }
    }
}

public protocol KeyAppTokenProvider {
    /// Get token metadata
    func getTokensInfo(_ args: KeyAppToken.Params<KeyAppToken.GetToken>) async throws
        -> [KeyAppToken.GetTokenInfoResult]

    /// Get token price
    func getTokensPrice(_ args: KeyAppToken.Params<KeyAppToken.GetToken>) async throws
        -> [KeyAppToken.GetPriceInfoResult]

    func getTokens() async throws
}

public class KeyAppTokenHttpProvider: KeyAppTokenProvider {
    let client: HTTPJSONRPCCLient

    public init(client: HTTPJSONRPCCLient) {
        self.client = client
    }

    public func getTokensInfo(_ args: KeyAppToken.Params<KeyAppToken.GetToken>) async throws
    -> [KeyAppToken.GetTokenInfoResult] {
        try await client.call(method: "get_tokens_info", params: args)
    }

    public func getTokensPrice(_ args: KeyAppToken.Params<KeyAppToken.GetToken>) async throws
    -> [KeyAppToken.GetPriceInfoResult] {
        try await client.call(method: "get_tokens_price", params: args)
    }

    public func getTokens() async throws {}
}
