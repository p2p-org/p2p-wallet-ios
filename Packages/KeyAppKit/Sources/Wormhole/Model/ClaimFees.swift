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

    public let gasInToken: TokenAmount?

    public let arbiter: TokenAmount

    public let createAccount: TokenAmount?

    enum CodingKeys: String, CodingKey {
        case gas
        case arbiter
        case createAccount = "create_account"
        case gasInToken = "gas_in_token"
    }

    public var totalInFiat: CurrencyAmount {
        gas.asCurrencyAmount
            + arbiter.asCurrencyAmount
            + createAccount?.asCurrencyAmount
    }
}
