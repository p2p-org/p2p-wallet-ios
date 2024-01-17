import FeeRelayerSwift
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift

public protocol SendChooseFeeService {
    func getAvailableWalletsToPayFee(feeInSOL: FeeAmount, whiteListMints: [String]) async throws -> [SolanaAccount]
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

    public func getAvailableWalletsToPayFee(
        feeInSOL: FeeAmount,
        whiteListMints: [String]
    ) async throws -> [SolanaAccount] {
        let filteredWallets = wallets
            .filter { $0.lamports > 0 && whiteListMints.contains($0.mintAddress) }

        var feeWallets = [SolanaAccount]()
        for element in filteredWallets {
            if element.token.mintAddress == PublicKey.wrappedSOLMint
                .base58EncodedString && element.lamports >= feeInSOL.total
            {
                feeWallets.append(element)
                continue
            }
            do {
                let feeAmount = try await feeRelayer.feeCalculator.calculateFeeInPayingToken(
                    orcaSwap: orcaSwap,
                    feeInSOL: feeInSOL,
                    payingFeeTokenMint: PublicKey(string: element.token.mintAddress)
                )
                if (feeAmount?.total ?? 0) <= element.lamports {
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
