import Foundation
import SolanaSwift

public struct JupiterSwapRouteUpdateUserWalletsResult {
    public let swapTokens: [SwapToken]
    public let fromToken: SwapToken
    public let toToken: SwapToken
    public let shouldRefreshRoute: Bool
}

extension JupiterSwapBusinessLogicHelper {
    static func updateUserWallets(
        currentSwapTokens swapTokens: [SwapToken],
        currentFromToken: SwapToken,
        currentToToken: SwapToken,
        newUserWallet: [Wallet]
    ) -> JupiterSwapRouteUpdateUserWalletsResult {
        // map updated user wallet to swapTokens
        let swapTokens = swapTokens.map { swapToken in
            if let userWallet = newUserWallet.first(where: { $0.token.address == swapToken.address }) {
                return SwapToken(token: swapToken.token, userWallet: userWallet)
            }
            return SwapToken(token: swapToken.token, userWallet: nil)
        }
        
        // update from Token
        let fromUserWallet: Wallet = newUserWallet
            .first(where: {
                $0.pubkey == currentFromToken.userWallet?.pubkey &&
                $0.token.address == currentFromToken.address
            })
            ??
            newUserWallet.first(where: {
                $0.token.address == PublicKey.usdcMint.base58EncodedString
            })
            ??
            newUserWallet.first(where: {
                $0.isNativeSOL
            })
            ??
            .init(token: .usdc)
        
        // from token
        let fromToken = SwapToken(
            token: fromUserWallet.token,
            userWallet: fromUserWallet
        )
        
        // update toToken
        let toUserWallet = newUserWallet
            .first(where: {
                $0.pubkey == currentToToken.userWallet?.pubkey &&
                $0.token.address == currentToToken.address
            })
            ??
            autoChooseToToken(for: fromToken, from: swapTokens)
            ??
            .init(token: .nativeSolana)
        
        // to token
        let toToken = SwapToken(
            token: toUserWallet.token,
            userWallet: toUserWallet
        )
        
        // if from and to token stay unchanged, update only the token with new balance, not the route
        return .init(
            swapTokens: swapTokens,
            fromToken: fromToken,
            toToken: toToken,
            shouldRefreshRoute: fromToken.address != currentFromToken.address
                || toToken.address != currentFromToken.address
        )
    }
    
    private static func autoChooseToToken(
        for fromToken: SwapToken,
        from swapTokens: [SwapToken]
    ) -> Wallet? {
        let usdc = swapTokens.first(where: { $0.address == SolanaSwift.Token.usdc.address && $0.userWallet != nil })
        let solana = swapTokens.first(where: { $0.address == SolanaSwift.Token.nativeSolana.address && $0.userWallet != nil })
        
        if let solana, fromToken.address == usdc?.address {
            return solana.userWallet
        } else if let usdc {
            return usdc.userWallet
        }
        
        return nil
    }
}
