import SolanaSwift

struct JupiterSwapTransaction: SwapRawTransactionType {
    let authority: String?
    let amountFrom: Double
    let amountTo: Double
    let sourceWallet: Wallet
    let destinationWallet: Wallet
    let fromAmount: Double
    let toAmount: Double
    let slippage: Double
    let metaInfo: SwapMetaInfo
    
    var payingFeeWallet: SolanaSwift.Wallet?
    var feeAmount: SolanaSwift.FeeAmount
    
    var mainDescription: String {
        [
            amountFrom.tokenAmountFormattedString(symbol: sourceWallet.token.symbol, maximumFractionDigits: Int(sourceWallet.token.decimals)),
            amountTo.tokenAmountFormattedString(symbol: destinationWallet.token.symbol, maximumFractionDigits: Int(destinationWallet.token.decimals))
        ].joined(separator: " → ")
    }

    let execution: () async throws -> TransactionID

    func createRequest() async throws -> String {
        try await execution()
    }
}
