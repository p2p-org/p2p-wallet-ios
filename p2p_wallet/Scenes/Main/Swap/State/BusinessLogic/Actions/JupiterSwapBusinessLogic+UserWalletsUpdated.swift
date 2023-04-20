//
//  JupiterSwapBusinessLogic+UserWalletsUpdated.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/02/2023.
//

import Foundation
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func updateUserWallets(
        state: JupiterSwapState,
        userWallets: [Wallet],
        services: JupiterSwapServices
    ) -> JupiterSwapState {
        // map updated user wallet to swapTokens
        let swapTokens = state.swapTokens.map { swapToken in
            if let userWallet = userWallets.first(where: { $0.mintAddress == swapToken.address }) {
                return SwapToken(token: swapToken.token, userWallet: userWallet)
            }
            return SwapToken(token: swapToken.token, userWallet: nil)
        }

        var fromToken: SwapToken?
        // update from Token only if it is from userWallets
        if let fromUserWallet = userWallets
            .first(where: {
                $0.pubkey == state.fromToken.userWallet?.pubkey &&
                $0.mintAddress == state.fromToken.address
            }) {
            fromToken = SwapToken(
                token: fromUserWallet.token,
                userWallet: fromUserWallet
            )
        }

        // update toToken only if it is from userWallets
        var toToken: SwapToken?
        if let toUserWallet: Wallet = userWallets
            .first(where: {
                $0.pubkey == state.toToken.userWallet?.pubkey &&
                $0.mintAddress == state.toToken.address
            })
        {
            toToken = SwapToken(
                token: toUserWallet.token,
                userWallet: toUserWallet
            )
        }

        // if from and to token stay unchanged, update only the tokens with new balance, not the route
        return state.modified {
            $0.swapTokens = swapTokens
            $0.fromToken = fromToken ?? state.fromToken
            $0.toToken = toToken ?? state.toToken
        }
    }
}
