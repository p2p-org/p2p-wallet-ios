import SolanaSwift
import Jupiter
import Resolver

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
    let swapTransaction: Jupiter.SwapTransaction?
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
                swapTransaction: swapTransaction?.stringValue,
                route: route,
                services: services
            )
        } catch {
            // Send error log
            
            let titleTag: String
            switch error {
            case let error as APIClientError:
                titleTag = error.titleTag
            default:
                titleTag = "unknown"
            }
            
            let title = "Swap iOS Alarm (#\(titleTag))"
            
            let data = await AlertLoggerDataBuilder.buildLoggerData(error: error)
            
            let diffRoutesTime = (Date().timeIntervalSince1970 - (route._receiveAt ?? Date()).timeIntervalSince1970)
                .toString(minimumFractionDigits: 9)
            
            let diffTxTime = (Date().timeIntervalSince1970 - (swapTransaction?.receivedAt ?? Date()).timeIntervalSince1970)
                .toString(minimumFractionDigits: 9)
            
            DefaultLogManager.shared.log(
                event: title,
                logLevel: .alert,
                data: SwapAlertLoggerMessage(
                    tokenA: .init(
                        name: sourceWallet.token.name,
                        mint: sourceWallet.token.address,
                        sendAmount: fromAmount.toString(maximumFractionDigits: 9),
                        balance: sourceWallet.amount?.toString(maximumFractionDigits: 9) ?? ""
                    ),
                    tokenB: .init(
                        name: destinationWallet.token.name,
                        mint: destinationWallet.token.address,
                        expectedAmount: toAmount.toString(maximumFractionDigits: 9),
                        balance: destinationWallet.amount?.toString(maximumFractionDigits: 9) ?? ""
                    ),
                    route: route.jsonString ?? "",
                    userPubkey: data.userPubkey,
                    slippage: slippage.toString(),
                    feeRelayerTransaction: swapTransaction?.stringValue ?? "",
                    platform: data.platform,
                    appVersion: data.appVersion,
                    timestamp: data.timestamp,
                    blockchainError: data.blockchainError ?? data.feeRelayerError ?? "",
                    diffRoutesTime: diffRoutesTime,
                    diffTxTime: diffTxTime
                )
            )
            throw error
        }
    }
}

// MARK: - Helper

private extension APIClientError {
    var titleTag: String {
        let titleTag: String
        switch self {
        case .responseError(let response) where response.data?.logs?
                .contains(where: { $0.contains("Slippage tolerance exceeded") }) == true :
            titleTag = "low_slippage"
        default:
            titleTag = "blockchain"
        }
        return titleTag
    }
}
