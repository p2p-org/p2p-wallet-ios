//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation
import KeyAppKitCore

public struct EthereumFees: Codable, Hashable {
    public let gas: Fee

    public let arbiter: Fee

    public let createAccount: Fee?
    
    enum CodingKeys: String, CodingKey {
        case gas
        case arbiter
        case createAccount = "create_account"
    }

    public var totalInUSD: Decimal {
        return (Decimal(string: gas.usdAmount) ?? 0.0) +
            (Decimal(string: arbiter.usdAmount) ?? 0.0) +
            (Decimal(string: createAccount?.usdAmount ?? "0.0") ?? 0.0)
    }
}

public struct Fee: Codable, Hashable {
    public let amount: String
    public let usdAmount: String

    private let chain: String
    private let token: String?

    public var feeToken: FeeToken {
        try! .init(chain: chain, token: token)
    }

    enum CodingKeys: String, CodingKey {
        case amount
        case usdAmount = "usd_amount"
        case chain
        case token
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.amount = try container.decode(String.self, forKey: .amount)
        self.usdAmount = try container.decode(String.self, forKey: .usdAmount)
        self.chain = try container.decode(String.self, forKey: .chain)
        self.token = try container.decodeIfPresent(String.self, forKey: .token)

        switch chain {
        case "Ethereum", "Solana":
            return
        default:
            throw CodingError.invalidValue
        }
    }
}

public extension CurrencyAmount {
    init(fee: Fee) {
        self.init(value: Decimal(string: fee.usdAmount) ?? 0.0, currencyCode: "USD")
    }
}

public enum FeeToken: Codable, Hashable {
    case ethereum(String?)
    case solana(String?)

    public init(chain: String, token: String?) throws {
        switch chain {
        case "Ethereum":
            self = .ethereum(token)
        case "Solana":
            self = .solana(token)
        default:
            throw CodingError.invalidValue
        }
    }
}
