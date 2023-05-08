import SolanaSwift
import Jupiter
import KeyAppKitCore

struct JupiterSwapTransaction: SwapRawTransactionType {
    let authority: String?
    let sourceAccount: SolanaAccount
    let destinationAccount: SolanaAccount
    let fromAmount: Double
    let toAmount: Double
    let slippage: Double
    let metaInfo: SwapMetaInfo
    
    var payingFeeWallet: SolanaAccount?
    var feeAmount: SolanaSwift.FeeAmount
    let route: Route
    let account: KeyPair
    let swapTransaction: String?
    let services: JupiterSwapServices
    
    
    var mainDescription: String {
        [
            fromAmount.tokenAmountFormattedString(symbol: sourceAccount.token.symbol, maximumFractionDigits: Int(sourceAccount.token.decimals)),
            toAmount.tokenAmountFormattedString(symbol: destinationAccount.token.symbol, maximumFractionDigits: Int(destinationAccount.token.decimals))
        ].joined(separator: " → ")
    }

    func createRequest() async throws -> String {
        try await JupiterSwapBusinessLogic.sendToBlockchain(
            account: account,
            swapTransaction: swapTransaction,
            route: route,
            services: services
        )
    }
}
