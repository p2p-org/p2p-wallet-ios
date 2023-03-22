//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation
import KeyAppKitCore

public struct ClaimFees: Codable, Hashable {
    public let gas: TokenAmount

    public let arbiter: TokenAmount

    public let createAccount: TokenAmount?

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

