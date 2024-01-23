import Foundation
import KeyAppKitCore
import SolanaSwift

public struct UserWalletEnvironments: Equatable {
    let wallets: [SolanaAccount]
    let ethereumAccount: String?

    let exchangeRate: [String: TokenPrice]
    let tokens: Set<TokenMetadata>

    var userWalletAddress: String? {
        wallets.first(where: { $0.isNative && $0.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString })?
            .address
    }

    public init(
        wallets: [SolanaAccount],
        ethereumAccount: String?,
        exchangeRate: [String: TokenPrice],
        tokens: Set<TokenMetadata>
    ) {
        self.wallets = wallets
        self.ethereumAccount = ethereumAccount
        self.exchangeRate = exchangeRate
        self.tokens = tokens
    }

    public static var empty: Self {
        .init(
            wallets: [],
            ethereumAccount: nil,
            exchangeRate: [:],
            tokens: []
        )
    }

    public func copy(tokens: Set<TokenMetadata>? = nil) -> Self {
        .init(
            wallets: wallets,
            ethereumAccount: ethereumAccount,
            exchangeRate: exchangeRate,
            tokens: tokens ?? self.tokens
        )
    }
}
