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
            let content: String
            switch error {
            case let error as APIClientError:
                content = error.content
            default:
                content = "\(error)"
            }
            
            JupiterSwapBusinessLogic.sendErrorLog(
                .init(
                    title: "Swap failed",
                    message: .init(
                        tokenA: .init(name: sourceWallet.token.name, mint: sourceWallet.token.address, sendAmount: fromAmount.toString()),
                        tokenB: .init(name: destinationWallet.token.name, mint: destinationWallet.token.address, expectedAmount: toAmount.toString()),
                        route: route.jsonString ?? "",
                        userPubkey: Resolver.resolve(UserWalletManager.self)
                            .wallet?.account.publicKey
                            .base58EncodedString ?? "",
                        slippage: slippage.toString(),
                        feeRelayerTransaction: swapTransaction ?? "",
                        platform: "iOS",
                        appVersion: AppInfo.appVersionDetail,
                        timestamp: "\(Date().timeIntervalSince1970)",
                        blockchainError: content
                    )
                )
            )
            throw error
        }
    }
}

// MARK: - Helper

private extension APIClientError {
    var content: String {
        switch self {
        case .cantEncodeParams:
            return "cantEncodeParams"
        case .invalidAPIURL:
            return "invalidAPIURL"
        case .invalidResponse:
            return "emptyResponse"
        case .responseError(let responseError):
            guard let data = try? JSONEncoder().encode(responseError),
                  let string = String(data: data, encoding: .utf8)
            else {
                return "unknownResponseError"
            }
            return string
        }
    }
}
