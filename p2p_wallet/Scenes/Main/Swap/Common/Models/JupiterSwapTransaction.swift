import SolanaSwift
import Jupiter

struct JupiterSwapTransaction: SwapRawTransactionType {
    let authority: String?
    let sourceWallet: Wallet
    let destinationWallet: Wallet
    let fromAmount: Double
    let toAmount: Double
    let slippage: Double
    let metaInfo: SwapMetaInfo
    
    var payingFeeWallet: SolanaSwift.Wallet?
    var feeAmount: SolanaSwift.FeeAmount
    let route: Route
    let account: KeyPair
    let swapTransaction: String?
    let services: JupiterSwapServices
    
    
    var mainDescription: String {
        [
            fromAmount.tokenAmountFormattedString(symbol: sourceWallet.token.symbol, maximumFractionDigits: Int(sourceWallet.token.decimals)),
            toAmount.tokenAmountFormattedString(symbol: destinationWallet.token.symbol, maximumFractionDigits: Int(destinationWallet.token.decimals))
        ].joined(separator: " → ")
    }

    func createRequest() async throws -> String {
        do {
            return try await JupiterSwapBusinessLogic.sendToBlockchain(
                account: account,
                swapTransaction: swapTransaction,
                route: route,
                services: services
            )
        } catch {
            sendLog(error)
            throw error
        }
    }
    
    
}

// MARK: - Helpers

private func sendLog(_ error: Error) {
    switch error {
    case let error as APIClientError:
        switch error {
        case let .responseError(response) where
            response.message == "Transaction simulation failed: Blockhash not found" ||
            response.message?.hasSuffix("custom program error: 0x1786") == true:
            return true
        default:
            return false
        }
    default:
        return
    }
}
