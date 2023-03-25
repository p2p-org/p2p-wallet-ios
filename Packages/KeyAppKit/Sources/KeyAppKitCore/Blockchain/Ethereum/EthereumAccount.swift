//
//  File.swift
//
//
//  Created by Giang Long Tran on 25.03.2023.
//

import BigInt
import Foundation

public struct EthereumAccount: Equatable {
    public let address: String
    public let token: EthereumToken
    public let balance: BigUInt
    public var price: TokenPrice?

    public init(address: String, token: EthereumToken, balance: BigUInt, price: TokenPrice? = nil) {
        self.address = address
        self.token = token
        self.balance = balance
        self.price = price
    }

    /// Convert balance into user-friendly format by using decimals.
    public var representedBalance: CryptoAmount {
        return .init(
            amount: balance,
            token: token
        )
    }

    /// Balance in fiat
    public var balanceInFiat: CurrencyAmount? {
        guard
            let price,
            let rate = price.value
        else {
            return nil
        }

        return .init(
            value: representedBalance.amount * rate,
            currencyCode: price.currencyCode
        )
    }
}
