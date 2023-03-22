//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import Foundation
import KeyAppKitCore

public struct SendFees: Codable, Hashable {
    public let arbiter: TokenAmount
    public let networkFee: TokenAmount?
    public let messageAccountRent: TokenAmount?
    public let bridgeFee: TokenAmount?

    enum CodingKeys: String, CodingKey {
        case arbiter
        case networkFee = "network_fee"
        case messageAccountRent = "message_account_rent"
        case bridgeFee = "bridge_fee"
    }
}

public extension SendFees {
    var totalInFiat: CurrencyAmount {
        arbiter.asCurrencyAmount
            + networkFee?.asCurrencyAmount
            + messageAccountRent?.asCurrencyAmount
            + bridgeFee?.asCurrencyAmount
    }
}
