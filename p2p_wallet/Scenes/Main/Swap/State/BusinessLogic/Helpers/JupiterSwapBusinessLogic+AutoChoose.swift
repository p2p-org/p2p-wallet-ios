import Jupiter
import KeyAppKitCore
import SolanaSwift

extension JupiterSwapBusinessLogic {
    /// Auto choose token logic
    static func autoChoose(swapTokens: [SwapToken]) -> (fromToken: SwapToken, toToken: SwapToken)? {
        let usdc = swapTokens.first(where: { $0.mintAddress == SolanaToken.usdc.mintAddress })
        let solana = swapTokens.first(where: { $0.mintAddress == SolanaToken.nativeSolana.mintAddress })

        let userWallets = swapTokens.compactMap(\.userWallet).filter { $0.lamports > 0 }

        if userWallets.isEmpty, let usdc, let solana {
            return (usdc, solana)
        } else if let usdcWallet = usdc?.userWallet, let usdc, let solana, usdcWallet.lamports > 0 {
            return (usdc, solana)
        } else if let solanaWallet = solana?.userWallet, let usdc, let solana, solanaWallet.lamports > 0 {
            return (solana, usdc)
        } else if let solana {
            let userWallet = userWallets.sorted(by: { $0.amountInCurrentFiat > $1.amountInCurrentFiat }).first
            let swapToken = swapTokens.first(where: { $0.mintAddress == userWallet?.mintAddress })
            if let swapToken {
                return (swapToken, solana)
            }
        }

        return nil
    }

    static func autoChooseToToken(for preChosenFromToken: SwapToken, from swapTokens: [SwapToken]) -> SwapToken? {
        let usdc = swapTokens.first(where: { $0.mintAddress == SolanaToken.usdc.mintAddress })
        let solana = swapTokens.first(where: { $0.mintAddress == SolanaToken.nativeSolana.mintAddress })

        if let solana, preChosenFromToken.mintAddress == usdc?.mintAddress {
            return solana
        } else if let usdc {
            return usdc
        }

        return nil
    }
}
