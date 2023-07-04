//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation
import KeyAppKitCore

public struct ClaimFees: Codable, Hashable, Equatable {
    // Gas in SOL
    public let gas: TokenAmount

    // Gas in same token that we user claims
    public let gasInToken: TokenAmount?

    // Gas in ethereum network
    public let arbiter: TokenAmount?

    // In same token that we user claims
    public let createAccount: TokenAmount?

    enum CodingKeys: String, CodingKey {
        case gas
        case arbiter
        case createAccount = "create_account"
        case gasInToken = "gas_in_token"
    }
    
    public var totalInFiat: CurrencyAmount {
        gas.asCurrencyAmount
            + arbiter?.asCurrencyAmount
            + createAccount?.asCurrencyAmount
    }
}
