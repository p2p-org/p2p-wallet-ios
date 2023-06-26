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
    
    func findPosibleDestinationMints(fromMint: String) throws -> [String] {
        fatalError()
    }
    
    func getTradablePoolsPairs(fromMint: String, toMint: String) async throws -> [OrcaSwapSwift.PoolsPair] {
        fatalError()
    }
    
    func findBestPoolsPairForInputAmount(_ inputAmount: UInt64, from poolsPairs: [OrcaSwapSwift.PoolsPair], prefersDirectSwap: Bool) throws -> OrcaSwapSwift.PoolsPair? {
        fatalError()
    }
    
    func findBestPoolsPairForEstimatedAmount(_ estimatedAmount: UInt64, from poolsPairs: [OrcaSwapSwift.PoolsPair], prefersDirectSwap: Bool) throws -> OrcaSwapSwift.PoolsPair? {
        fatalError()
    }
    
    func getLiquidityProviderFee(bestPoolsPair: OrcaSwapSwift.PoolsPair?, inputAmount: Double?, slippage: Double) throws -> [UInt64] {
        fatalError()
    }
    
    func getNetworkFees(myWalletsMints: [String], fromWalletPubkey: String, toWalletPubkey: String?, bestPoolsPair: OrcaSwapSwift.PoolsPair?, inputAmount: Double?, slippage: Double, lamportsPerSignature: UInt64, minRentExempt: UInt64) async throws -> SolanaSwift.FeeAmount {
        fatalError()
    }
    
    func prepareForSwapping(fromWalletPubkey: String, toWalletPubkey: String?, bestPoolsPair: OrcaSwapSwift.PoolsPair, amount: Double, feePayer: SolanaSwift.PublicKey?, slippage: Double) async throws -> ([OrcaSwapSwift.PreparedSwapTransaction], String?) {
        fatalError()
    }
    
    func swap(fromWalletPubkey: String, toWalletPubkey: String?, bestPoolsPair: OrcaSwapSwift.PoolsPair, amount: Double, slippage: Double, isSimulation: Bool) async throws -> SolanaSwift.SwapResponse {
        fatalError()
    }
}
