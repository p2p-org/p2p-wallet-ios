import Foundation
import KeyAppKitCore
import SolanaSwift

public struct RecipientSearchConfig {
    public var wallets: [SolanaAccount]
    public var ethereumAccount: String?
    public var tokens: [String: TokenMetadata]

    public var ethereumSearch: Bool

    public init(
        wallets: [SolanaAccount],
        ethereumAccount: String?,
        tokens: [String: TokenMetadata],
        ethereumSearch: Bool
    ) {
        self.wallets = wallets
        self.ethereumAccount = ethereumAccount
        self.tokens = tokens
        self.ethereumSearch = ethereumSearch
    }

    public init() {
        wallets = []
        ethereumAccount = nil
        tokens = [:]
        ethereumSearch = false
    }
}
