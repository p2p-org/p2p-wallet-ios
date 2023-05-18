import SolanaSwift
import OrcaSwapSwift
import FeeRelayerSwift

public protocol SendChooseFeeService {
    func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet]
}

public final class SendChooseFeeServiceImpl: SendChooseFeeService {

    private let orcaSwap: OrcaSwapType
    private let feeRelayer: RelayService
    private let wallets: [Wallet]

    public init(wallets: [Wallet], feeRelayer: RelayService, orcaSwap: OrcaSwapType) {
        self.wallets = wallets
        self.feeRelayer = feeRelayer
        self.orcaSwap = orcaSwap
    }

    public func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet] {
        let filteredWallets = wallets.filter { ($0.lamports ?? 0) > 0 }
        var feeWallets = [Wallet]()
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
