import FeeRelayerSwift
import OrcaSwapSwift
import SolanaSwift

public protocol SwapService {
    func calculateFeeInPayingToken(feeInSOL: FeeAmount, payingFeeTokenMint: PublicKey) async throws -> FeeAmount?
}

public struct MockedSwapService: SwapService {
    let result: FeeAmount?

    public init(result: FeeAmount?) { self.result = result }

    public func calculateFeeInPayingToken(
        feeInSOL _: FeeAmount,
        payingFeeTokenMint _: PublicKey
    ) async throws -> FeeAmount? { result }
}

public class SwapServiceImpl: SwapService {
    private let feeRelayerCalculator: RelayFeeCalculator
    private let orcaSwap: OrcaSwapType

    public init(
        feeRelayerCalculator: RelayFeeCalculator,
        orcaSwap: OrcaSwapType
    ) {
        self.feeRelayerCalculator = feeRelayerCalculator
        self.orcaSwap = orcaSwap
    }

    public func calculateFeeInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeTokenMint: PublicKey
    ) async throws -> FeeAmount? {
        try await feeRelayerCalculator.calculateFeeInPayingToken(
            orcaSwap: orcaSwap,
            feeInSOL: feeInSOL,
            payingFeeTokenMint: payingFeeTokenMint
        )
    }
}
