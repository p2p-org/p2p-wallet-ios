//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import Foundation
import KeyAppKitCore

public struct SendFees: Codable, Hashable, Equatable {
    /// Receive amount for user B. Nil when fees are greater than sending amount.
    public let resultAmount: TokenAmount?
    
    /// Process fee in Ethereum network.
    public let arbiter: TokenAmount?
    
    /// Network fee in Solana network.
    public let networkFee: TokenAmount?
    
    /// Account creation fee in Solana network.
    public let messageAccountRent: TokenAmount?
    
    /// Bridge fee in Solana network.
    public let bridgeFee: TokenAmount?

    enum CodingKeys: String, CodingKey {
        case resultAmount = "result_amount"
        case arbiter = "arbiter_fee"
        case networkFee = "network_fee"
        case messageAccountRent = "message_account_rent"
        case bridgeFee = "bridge_fee"
    }
}

public extension SendFees {
    /// Total amount in fiat.
    var totalInFiat: CurrencyAmount {
        CurrencyAmount(usd: 0)
            + arbiter?.asCurrencyAmount
            + networkFee?.asCurrencyAmount
            + messageAccountRent?.asCurrencyAmount
            + bridgeFee?.asCurrencyAmount
    }
}
