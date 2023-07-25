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
public struct SolanaAccount: Identifiable, Equatable, Hashable {
    public var id: String { token.id }

    public var address: String

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

    @available(*, deprecated)
    public init(pubkey: String? = nil, lamports: Lamports? = nil, token: TokenMetadata) {
        address = pubkey ?? ""
        self.lamports = lamports ?? 0
        self.token = token
        price = nil
    }

    public var cryptoAmount: CryptoAmount {
        .init(uint64: lamports, token: token)
    }

    /// Get current amount in fiat.
    public var amountInFiat: CurrencyAmount? {
        guard let price else { return nil }
        return cryptoAmount.unsafeToFiatAmount(price: price)
    }
}

public extension SolanaAccount {
    var mintAddress: String {
        token.mintAddress
    }

    @available(*, deprecated, renamed: "address")
    var pubkey: String? {
        get {
            address
        }
        set {
            address = newValue ?? ""
        }
    }

    @available(*, deprecated, message: "Migrate to amountInFiat")
    var amountInFiatDouble: Double {
        guard let amountInFiat else { return 0.0 }
        return Double(amountInFiat.value.description) ?? 0.0
    }

    @available(*, deprecated, message: "Legacy code")
    var amountInCurrentFiat: Double {
        amountInFiatDouble
    }

    @available(*, deprecated, message: "Legacy code")
    var priceInCurrentFiat: Double? {
        guard let price = price?.value.description else { return 0.0 }
        return Double(price) ?? 0.0
    }

    @available(*, deprecated, message: "Legacy code")
    var amount: Double? {
        lamports.convertToBalance(decimals: token.decimals)
    }

    @available(*, deprecated, message: "Legacy code")
    static func nativeSolana(pubkey: String?, lamport: Lamports?) -> Self {
        .init(pubkey: pubkey, lamports: lamport, token: .nativeSolana)
    }
}
