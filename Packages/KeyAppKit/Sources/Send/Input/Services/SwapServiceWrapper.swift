import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import Resolver
import SolanaSwift

public class SwapServiceWrapper: Send.SwapService {
    let orcaSwap: OrcaSwap
    let relayService: RelayService

    public init(orcaSwap: OrcaSwap, relayService: RelayService) {
        self.orcaSwap = orcaSwap
        self.relayService = relayService
    }

    public func calculateFeeInPayingToken(
        feeInSOL: SolanaSwift.FeeAmount,
        payingFeeTokenMint: SolanaSwift.PublicKey
    ) async throws -> SolanaSwift.FeeAmount? {
        try await orcaSwap.load()
        return try await relayService.feeCalculator.calculateFeeInPayingToken(
            orcaSwap: orcaSwap,
            feeInSOL: feeInSOL,
            payingFeeTokenMint: payingFeeTokenMint
        )
    }
}
