import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    /// Auto choose token logic
    static func autoChoose(swapTokens: [SwapToken]) -> (fromToken: SwapToken, toToken: SwapToken)? {
        let usdc = swapTokens.first(where: { $0.address == SolanaSwift.Token.usdc.address })
        let solana = swapTokens.first(where: { $0.address == SolanaSwift.Token.nativeSolana.address })

        let userWallets = swapTokens.compactMap { $0.userWallet }.filter({ $0.amount > 0 })

        if userWallets.isEmpty, let usdc, let solana {
            return (usdc, solana)
        } else if let usdcWallet = usdc?.userWallet, let usdc, let solana, usdcWallet.amount > 0 {
            return (usdc, solana)
        } else if let solanaWallet = solana?.userWallet, let usdc, let solana, solanaWallet.amount > 0 {
            return (solana, usdc)
        } else if let solana {
            let userWallet = userWallets.sorted(by: { $0._amountInCurrentFiat > $1._amountInCurrentFiat }).first
            let swapToken = swapTokens.first(where: { $0.address == userWallet?.mintAddress })
            if let swapToken {
                return (swapToken, solana)
            }
        }

        return nil
    }

    static func autoChooseToToken(for fromToken: SwapToken, from swapTokens: [SwapToken]) -> SwapToken? {
        let usdc = swapTokens.first(where: { $0.address == SolanaSwift.Token.usdc.address })
        let solana = swapTokens.first(where: { $0.address == SolanaSwift.Token.nativeSolana.address })

        if let solana, fromToken.address == usdc?.address {
            return solana
        } else if let usdc {
            return usdc
        }

        return nil
    }
}
