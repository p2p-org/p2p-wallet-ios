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
public struct SolanaAccount: Identifiable, Hashable {
    // MARK: - Properties
    
    public var pubkey: String?
    public var lamports: UInt64?
    public var token: Token
    
    @available(*, deprecated)
    public var userInfo: AnyHashable?
    public let supply: UInt64?
    
    /// The fetched price at current moment of time.
    public var price: TokenPrice?
    
    // MARK: - Initializer
    
    public init(
        pubkey: String? = nil,
        lamports: UInt64? = nil,
        supply: UInt64? = nil,
        price: TokenPrice? = nil,
        token: Token
    ) {
        self.pubkey = pubkey
        self.lamports = lamports
        self.supply = supply
        self.price = price
        self.token = token
    }
    
    // MARK: - Computed properties
    
    public var amount: Double? {
        lamports?.convertToBalance(decimals: token.decimals)
    }
    
    public var id: String {
        pubkey ?? token.address
    }
    
    public var isNativeSOL: Bool {
        token.isNativeSOL
    }
    
    public var mintAddress: String {
        token.address
    }
    
    // Hide NFT TODO: $0.token.supply == 1 is also a condition for NFT but skipped atm
    public var isNFTToken: Bool {
        token.decimals == 0
    }
    
    public var decimals: Int {
        Int(token.decimals)
    }
    
    public var cryptoAmount: CryptoAmount {
        .init(uint64: lamports ?? 0, token: token)
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
    
    // MARK: - Fabric methods
    
    public static func nativeSolana(
        pubkey: String?,
        lamport: UInt64?
    ) -> Self {
        .init(
            pubkey: pubkey,
            lamports: lamport,
            token: .nativeSolana
        )
    }
}

