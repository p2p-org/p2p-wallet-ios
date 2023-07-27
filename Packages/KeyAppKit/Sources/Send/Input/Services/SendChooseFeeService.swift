import FeeRelayerSwift
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift

public protocol SendChooseFeeService {
    func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [SolanaAccount]
}

public final class SendChooseFeeServiceImpl: SendChooseFeeService {
    private let orcaSwap: OrcaSwapType
    private let feeRelayer: RelayService
    private let wallets: [SolanaAccount]

    public init(wallets: [SolanaAccount], feeRelayer: RelayService, orcaSwap: OrcaSwapType) {
        self.wallets = wallets
        self.feeRelayer = feeRelayer
        self.orcaSwap = orcaSwap
    }

    public func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [SolanaAccount] {
        let filteredWallets = wallets.filter { ($0.lamports ?? 0) > 0 }
        var feeWallets = [SolanaAccount]()
        for element in filteredWallets {
            if element.token.mintAddress == PublicKey.wrappedSOLMint
                .base58EncodedString && (element.lamports ?? 0) >= feeInSOL.total
            {
                feeWallets.append(element)
                continue
            }
            do {
                let feeAmount = try await feeRelayer.feeCalculator.calculateFeeInPayingToken(
                    orcaSwap: orcaSwap,
                    feeInSOL: feeInSOL,
                    payingFeeTokenMint: try PublicKey(string: element.token.mintAddress)
                )
                if (feeAmount?.total ?? 0) <= (element.lamports ?? 0) {
                    feeWallets.append(element)
                }
            } catch {
                if (error as? FeeRelayerError) != FeeRelayerError.swapPoolsNotFound {
                    throw error
                }
            }
        }

        return feeWallets
    }
}
