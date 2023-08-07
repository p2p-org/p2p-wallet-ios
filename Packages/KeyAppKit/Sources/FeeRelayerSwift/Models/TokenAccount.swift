import Foundation
import SolanaSwift

/// A basic class that represents SPL TokenMetadata.
public struct TokenAccount: Equatable, Codable {
    public init(address: PublicKey, mint: PublicKey) {
        self.address = address
        self.mint = mint
    }

    /// A address of spl token.
    public let address: PublicKey

    /// A mint address for spl token.
    public let mint: PublicKey
}
