import Foundation
import OrcaSwapSwift
import SolanaSwift

/// Interface for a transaction builder
public protocol SwapTransactionBuilder {
    /// Prepare transaction
    /// - Parameters:
    ///   - userAccount: user's account
    ///   - pools: pools for swapping
    ///   - inputAmount: swapping input amount
    ///   - slippage: swap slippage
    ///   - sourceTokenAccount: source token
    ///   - destinationTokenMint: destination token mint
    ///   - destinationTokenAddress: (Optional) destination token's address, nil for not-yet-created token address
    ///   - blockhash: latest blockhash
    /// - Returns: prepared transactions and additional payback fee (optional)
    func buildSwapTransaction(
        userAccount: KeyPair,
        pools: PoolsPair,
        inputAmount: UInt64,
        slippage: Double,
        sourceTokenAccount: TokenAccount,
        destinationTokenMint: PublicKey,
        destinationTokenAddress: PublicKey?,
        blockhash: String
    ) async throws -> (transactions: [PreparedTransaction], additionalPaybackFee: UInt64)
}
