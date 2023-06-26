// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let orcaConfigs = try? newJSONDecoder().decode(OrcaConfigs.self, from: jsonData)

import Foundation
import SolanaSwift

// MARK: - OrcaConfigs
public struct OrcaInfo: Codable {
    public let pools: [String: Pool]
    public let programIds: ProgramIDS
    public let tokens: [String: TokenValue]

    public init(pools: [String: Pool], programIds: ProgramIDS, tokens: [String: TokenValue]) {
        self.pools = pools
        self.programIds = programIds
        self.tokens = tokens
    }
}

public enum TokenEnum: String, Codable {
    case tokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
}

// MARK: - ProgramIDS
public struct ProgramIDS: Codable {
    public let serumTokenSwap, tokenSwapV2, tokenSwap: String
    public let token: TokenEnum
    public let aquafarm: String

    public init(serumTokenSwap: String, tokenSwapV2: String, tokenSwap: String, token: TokenEnum, aquafarm: String) {
        self.serumTokenSwap = serumTokenSwap
        self.tokenSwapV2 = tokenSwapV2
        self.tokenSwap = tokenSwap
        self.token = token
        self.aquafarm = aquafarm
    }
}

// MARK: - TokenValue
public struct TokenValue: Codable {
    public let mint, name: String
    public let decimals: Int
    public let fetchPrice, poolToken: Bool?
    public let wrapper: String?

    public init(mint: String, name: String, decimals: Int, fetchPrice: Bool?, poolToken: Bool?, wrapper: String?) {
        self.mint = mint
        self.name = name
        self.decimals = decimals
        self.fetchPrice = fetchPrice
        self.poolToken = poolToken
        self.wrapper = wrapper
    }
}
