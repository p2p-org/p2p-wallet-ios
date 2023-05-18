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
    public var id: String {
        data.pubkey ?? data.token.address
    }

    /// Data field
    public var data: Wallet

    /// The fetched price at current moment of time.
    public var price: TokenPrice?

    public init(data: Wallet, price: TokenPrice? = nil) {
        self.data = data
        self.price = price
    }

    public var cryptoAmount: CryptoAmount {
        .init(uint64: data.lamports ?? 0, token: data.token)
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
