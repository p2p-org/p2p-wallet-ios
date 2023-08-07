import Foundation
import OrcaSwapSwift
import SolanaSwift

public protocol SwapFeeRelayerCalculator {
    func calculateSwappingNetworkFees(
        lamportsPerSignature: UInt64,
        minimumTokenAccountBalance: UInt64,
        swapPoolsCount: Int,
        sourceTokenMint: PublicKey,
        destinationTokenMint: PublicKey,
        destinationAddress: PublicKey?
    ) async throws -> FeeAmount
}
