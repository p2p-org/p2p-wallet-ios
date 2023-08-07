import Foundation
import OrcaSwapSwift
import SolanaSwift

extension SwapTransactionBuilderImpl {
    func checkTransitTokenAccount(
        owner _: PublicKey,
        poolsPair: PoolsPair,
        output: inout SwapTransactionBuilderOutput
    ) async throws {
        let transitToken = try? transitTokenAccountManager.getTransitToken(
            pools: poolsPair
        )

        let needsCreateTransitTokenAccount = try await transitTokenAccountManager
            .checkIfNeedsCreateTransitTokenAccount(
                transitToken: transitToken
            )

        output.needsCreateTransitTokenAccount = needsCreateTransitTokenAccount
        output.transitTokenAccountAddress = transitToken?.address
        output.transitTokenMintPubkey = transitToken?.mint
    }
}
