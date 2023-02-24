import SolanaSwift

struct JupiterSwapTransaction: RawTransactionType {
    let mainDescription: String
    let amountFiat: Double
    let fromToken: SwapToken
    let toToken: SwapToken
    var payingFeeWallet: Wallet? {
        guard let token = networkFees?.token else { return nil }
        return .init(lamports: 0, token: token)
    }

    var networkFees: (total: SolanaSwift.Lamports, token: SolanaSwift.Token)?

    private let execution: () async throws -> TransactionID

    init(
        execution: @escaping () async throws -> TransactionID,
        amountFrom: Double,
        amountTo: Double,
        fromToken: SwapToken,
        toToken: SwapToken,
        amountFromFiat: Double
    ) {
        self.execution = execution
        self.mainDescription = [
            amountFrom.tokenAmountFormattedString(symbol: fromToken.jupiterToken.symbol, maximumFractionDigits: fromToken.jupiterToken.decimals),
            amountTo.tokenAmountFormattedString(symbol: toToken.jupiterToken.symbol, maximumFractionDigits: toToken.jupiterToken.decimals)
        ].joined(separator: " → ")
        self.amountFiat = amountFromFiat
        self.fromToken = fromToken
        self.toToken = toToken
    }

    func createRequest() async throws -> String {
        try await execution()
    }
}
