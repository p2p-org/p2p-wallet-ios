//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation

public struct EthereumFees: Codable, Hashable {
    public let gas: Fee
    public let arbiter: Fee
    public let createAccount: Fee?

    public var totalInUSD: Decimal {
        return (Decimal(string: gas.usdAmount) ?? 0.0) +
            (Decimal(string: arbiter.usdAmount) ?? 0.0) +
            (Decimal(string: createAccount?.usdAmount ?? "0.0") ?? 0.0)
    }
}

public struct Fee: Codable, Hashable {
    public let amount: String
    public let usdAmount: String

    enum CodingKeys: String, CodingKey {
        case amount
        case usdAmount = "usd_amount"
    }
}
