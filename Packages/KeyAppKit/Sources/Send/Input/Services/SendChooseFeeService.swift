import SolanaSwift
import OrcaSwapSwift
import FeeRelayerSwift
import KeyAppKitCore

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
            if element.token.address == PublicKey.wrappedSOLMint.base58EncodedString && (element.lamports ?? 0) >= feeInSOL.total {
                feeWallets.append(element)
                continue
            }
            do {
                let feeAmount = try await self.feeRelayer.feeCalculator.calculateFeeInPayingToken(
                    orcaSwap: self.orcaSwap,
                    feeInSOL: feeInSOL,
                    payingFeeTokenMint: try PublicKey(string: element.token.address)
                )
                if (feeAmount?.total ?? 0) <= (element.lamports ?? 0) {
                    feeWallets.append(element)
                }
            }
            catch let error {
                if (error as? FeeRelayerError) != FeeRelayerError.swapPoolsNotFound {
                    throw error
                }
            }
        }
        
        return feeWallets
    }
}
