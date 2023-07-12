import OrcaSwapSwift
import SolanaSwift

class MockOrcaSwapBase: OrcaSwapType {
    func load() async throws {}

    func getMint(tokenName: String) -> String? {
        switch tokenName {
        case "BTC":
            return PublicKey.btcMint.base58EncodedString
        case "ETH":
            return PublicKey.ethMint.base58EncodedString
        case "SOL":
            return PublicKey.wrappedSOLMint.base58EncodedString
        case "USDT":
            return PublicKey.usdtMint.base58EncodedString
        default:
            fatalError()
        }
    }

    func findPosibleDestinationMints(fromMint _: String) throws -> [String] {
        fatalError()
    }

    func getTradablePoolsPairs(fromMint _: String, toMint _: String) async throws -> [OrcaSwapSwift.PoolsPair] {
        fatalError()
    }

    func findBestPoolsPairForInputAmount(_: UInt64, from _: [OrcaSwapSwift.PoolsPair],
                                         prefersDirectSwap _: Bool) throws -> OrcaSwapSwift.PoolsPair?
    {
        fatalError()
    }

    func findBestPoolsPairForEstimatedAmount(_: UInt64, from _: [OrcaSwapSwift.PoolsPair],
                                             prefersDirectSwap _: Bool) throws -> OrcaSwapSwift.PoolsPair?
    {
        fatalError()
    }

    func getLiquidityProviderFee(bestPoolsPair _: OrcaSwapSwift.PoolsPair?, inputAmount _: Double?,
                                 slippage _: Double) throws -> [UInt64]
    {
        fatalError()
    }

    func getNetworkFees(
        myWalletsMints _: [String],
        fromWalletPubkey _: String,
        toWalletPubkey _: String?,
        bestPoolsPair _: OrcaSwapSwift.PoolsPair?,
        inputAmount _: Double?,
        slippage _: Double,
        lamportsPerSignature _: UInt64,
        minRentExempt _: UInt64
    ) async throws -> SolanaSwift.FeeAmount {
        fatalError()
    }

    func prepareForSwapping(
        fromWalletPubkey _: String,
        toWalletPubkey _: String?,
        bestPoolsPair _: OrcaSwapSwift.PoolsPair,
        amount _: Double,
        feePayer _: SolanaSwift.PublicKey?,
        slippage _: Double
    ) async throws -> ([OrcaSwapSwift.PreparedSwapTransaction], String?) {
        fatalError()
    }

    func swap(
        fromWalletPubkey _: String,
        toWalletPubkey _: String?,
        bestPoolsPair _: OrcaSwapSwift.PoolsPair,
        amount _: Double,
        slippage _: Double,
        isSimulation _: Bool
    ) async throws -> SolanaSwift.SwapResponse {
        fatalError()
    }

    func swap(
        fromWalletPubkey _: String,
        toWalletPubkey _: String?,
        bestPoolsPair _: OrcaSwapSwift.PoolsPair,
        amount _: Double,
        slippage _: Double,
        isSimulation _: Bool
    ) async throws -> OrcaSwapSwift.SwapResponse {
        fatalError()
    }
}
