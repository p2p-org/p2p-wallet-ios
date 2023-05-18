//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation
import KeyAppKitCore

public struct ClaimFees: Codable, Hashable, Equatable {
    public let gas: TokenAmount

    public let arbiter: TokenAmount

    public let createAccount: TokenAmount?

    enum CodingKeys: String, CodingKey {
        case gas
        case arbiter
        case createAccount = "create_account"
    }

    public var totalInFiat: CurrencyAmount {
        return gas.asCurrencyAmount
            + arbiter.asCurrencyAmount
            + createAccount?.asCurrencyAmount
    }
}
