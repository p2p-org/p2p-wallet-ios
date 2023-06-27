import Foundation
import SolanaSwift

public struct JupiterSwapAutoSelectTokensResult {
    public let fromToken: SwapToken
    public let toToken: SwapToken
}

extension JupiterSwapBusinessLogicHelper {
    /// Auto choose token logic
    static func autoSelectTokens(swapTokens: [SwapToken]) -> JupiterSwapAutoSelectTokensResult {
        // get all userWallets that have amount > 0
        let userWallets = swapTokens
            .compactMap { $0.userWallet }
            .filter({ ($0.amount ?? 0) > 0 })
        
        // native sol token
        let solToken = swapTokens
            .first(where: {$0.token.address == Token.nativeSolana.address})
            ?? .init(token: .nativeSolana, userWallet: nil)
        
        // usdc token
        let usdcToken = swapTokens
            .first(where: {
                $0.userWallet?.token.address == Token.usdc.address &&
                ($0.userWallet?.lamports ?? 0) > 0
            })
            ?? .init(token: .usdc, userWallet: nil)
        
        // If user do not have any wallets, choose usdc - sol
        guard !userWallets.isEmpty else {
            return .init(
                fromToken: usdcToken,
                toToken: solToken
            )
        }

        // If user has usdc, choose usdc - sol
        if (usdcToken.userWallet?.lamports ?? 0) > 0 {
            return .init(fromToken: usdcToken, toToken: solToken)
        }
        
        // If user has sol, choose sol - usdc
        if (solToken.userWallet?.lamports ?? 0) > 0 {
            return .init(
                fromToken: solToken,
                toToken: usdcToken
            )
        }
        
        // If user do not have any SOL or usdc
        let fromToken = swapTokens
            .filter { !$0.token.isNativeSOL }
            .max {
                // TODO: - Amount in current fiat
                ($0.userWallet?.amount ?? 0) > ($1.userWallet?.amount ?? 0)
            }
        
        return .init(
            fromToken: fromToken ?? .init(token: .usdc, userWallet: nil),
            toToken: solToken
        )
    }
}
