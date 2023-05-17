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
            // Send error log
            
            let titleTag: String
            switch error {
            case let error as APIClientError:
                titleTag = error.titleTag
            default:
                titleTag = "unknown"
            }
            
            let title = "Swap iOS Alarm (#\(titleTag))"
            
            let content: String
            switch error {
            case let error as APIClientError:
                content = error.content
            default:
                content = "\(error)"
            }
            
            let message = SwapAlertLoggerMessage(
                tokenA: .init(
                    name: sourceWallet.token.name,
                    mint: sourceWallet.token.address,
                    sendAmount: fromAmount.toString(maximumFractionDigits: 9)
                ),
                tokenB: .init(
                    name: destinationWallet.token.name,
                    mint: destinationWallet.token.address,
                    expectedAmount: toAmount.toString(maximumFractionDigits: 9)
                ),
                route: route.jsonString ?? "",
                userPubkey: Resolver.resolve(UserWalletManager.self)
                    .wallet?.account.publicKey
                    .base58EncodedString ?? "",
                slippage: slippage.toString(),
                feeRelayerTransaction: swapTransaction ?? "",
                platform: "iOS \(await UIDevice.current.systemVersion)",
                appVersion: AppInfo.appVersionDetail,
                timestamp: "\(Int64(Date().timeIntervalSince1970 * 1000))",
                blockchainError: content
            )
            
            DefaultLogManager.shared.log(
                event: title,
                data: message.jsonString,
                logLevel: .alert
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
