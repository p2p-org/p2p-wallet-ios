import Foundation
import SolanaSwift

/// A basic class that represents SPL TokenMetadata.
public struct TokenAccount: Equatable, Codable {
    public init(
        address: PublicKey,
        mint: PublicKey,
        minimumTokenAccountBalance: UInt64
    ) {
        self.address = address
        self.mint = mint
        self.minimumTokenAccountBalance = minimumTokenAccountBalance
    }

    /// A address of spl token.
    public let address: PublicKey

    /// A mint address for spl token.
    public let mint: PublicKey

    /// Mint rent for token
    public let minimumTokenAccountBalance: UInt64
}
