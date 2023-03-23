//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import Foundation
import KeyAppKitCore

public struct TokenAmount: Codable, Hashable {
    public let amount: String
    public let usdAmount: String

    private let chain: String
    private let contract: String?

    public var token: WormholeToken

    enum CodingKeys: String, CodingKey {
        case amount
        case usdAmount = "usd_amount"
        case chain
        case contract = "token"
    }

    init(amount: String, usdAmount: String, chain: String, contract: String?) throws {
        self.amount = amount
        self.usdAmount = usdAmount
        self.chain = chain
        self.contract = contract
        self.token = try WormholeToken(chain: chain, token: contract)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.amount = try container.decode(String.self, forKey: .amount)
        self.usdAmount = try container.decode(String.self, forKey: .usdAmount)
        self.chain = try container.decode(String.self, forKey: .chain)
        self.contract = try container.decodeIfPresent(String.self, forKey: .contract)
        self.token = try WormholeToken(chain: chain, token: contract)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(usdAmount, forKey: .usdAmount)
        try container.encode(chain, forKey: .chain)
        try container.encodeIfPresent(contract, forKey: .contract)
    }
}

extension TokenAmount: CurrentyConverable {
    public var asCurrencyAmount: CurrencyAmount {
        .init(usd: Decimal(string: usdAmount) ?? 0)
    }
}