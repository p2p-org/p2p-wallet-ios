import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func autoChoose(swapTokens: [SwapToken]) throws -> (fromToken: SwapToken, toToken: SwapToken) {
        let usdc = swapTokens.first(where: { $0.address == SolanaSwift.Token.usdc.address })
        let solana = swapTokens.first(where: { $0.address == SolanaSwift.Token.nativeSolana.address })

        let userWallets = swapTokens.compactMap { $0.userWallet }

        if userWallets.isEmpty, let usdc, let solana {
            return (usdc, solana)
        } else if usdc?.userWallet != nil, let usdc, let solana {
            return (usdc, solana)
        } else if solana?.userWallet != nil, let usdc, let solana {
            return (solana, usdc)
        } else if let usdc {
            let userWallet = userWallets.sorted(by: { $0.amountInCurrentFiat > $1.amountInCurrentFiat }).first
            let swapToken = swapTokens.first(where: { $0.address == userWallet?.mintAddress })
            return (swapToken ?? solana ?? usdc, usdc)
        }

        throw JupiterSwapState.ErrorReason.unknown
    }

    static func autoChooseToToken(for fromToken: SwapToken, from swapTokens: [SwapToken]) throws -> SwapToken {
        let usdc = swapTokens.first(where: { $0.address == SolanaSwift.Token.usdc.address })
        let solana = swapTokens.first(where: { $0.address == SolanaSwift.Token.nativeSolana.address })

        if let usdc, fromToken.address == solana?.address {
            return usdc
        } else if let solana {
            return solana
        }

        throw JupiterSwapState.ErrorReason.unknown
    }
}
