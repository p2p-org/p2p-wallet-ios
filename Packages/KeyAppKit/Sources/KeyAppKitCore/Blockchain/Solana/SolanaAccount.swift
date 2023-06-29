//
//  File.swift
//
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import SolanaSwift

/// Solana account data structure.
/// This class is combination of raw account data and additional application data.
public struct SolanaAccount: Identifiable, Equatable {
    public var id: String { address }

    public let address: String

    public let lamports: Lamports

    /// Data field
    public var token: SolanaToken

    /// The fetched price at current moment of time.
    public var price: TokenPrice?

    public init(address: String, lamports: Lamports, token: SolanaToken, price: TokenPrice? = nil) {
        self.address = address
        self.lamports = lamports
        self.token = token
        self.price = price
    }

    public var cryptoAmount: CryptoAmount {
        .init(uint64: lamports, token: token)
    }

    /// Get current amount in fiat.
    public var amountInFiat: CurrencyAmount? {
        guard let price else { return nil }
        return cryptoAmount.unsafeToFiatAmount(price: price)
    }

    @available(*, deprecated, message: "Migrate to amountInFiat")
    public var amountInFiatDouble: Double {
        guard let amountInFiat else { return 0.0 }
        return Double(amountInFiat.value.description) ?? 0.0
    }
}
