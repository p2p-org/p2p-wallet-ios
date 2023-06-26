import Foundation
import OrcaSwapSwift
import SolanaSwift

/// Interface for a top up transaction builder
public protocol TopUpTransactionBuilder {
    /// Build top up transaction from given data
    /// - Parameters:
    ///   - context: Relay context
    ///   - sourceToken: fromToken to top up
    ///   - topUpPools: pools using for top up with swap
    ///   - targetAmount: amount for topping up
    ///   - blockhash: recent blockhash
    /// - Returns: swap data to pass to fee relayer api client and prepared top up transaction
    func buildTopUpTransaction(
        context: RelayContext,
        sourceToken: TokenAccount,
        topUpPools: PoolsPair,
        targetAmount: UInt64,
        blockhash: String
    ) async throws -> (swapData: FeeRelayerRelaySwapType, preparedTransaction: PreparedTransaction)
}
