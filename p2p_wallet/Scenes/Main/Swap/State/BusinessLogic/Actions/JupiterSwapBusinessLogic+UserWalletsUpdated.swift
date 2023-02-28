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
        userWallets: [Wallet]
    ) async throws -> JupiterSwapState {
        // map updated user wallet to swapTokens
        let swapTokens = state.swapTokens.map { swapToken in
            if let userWallet = userWallets.first(where: { $0.mintAddress == swapToken.address }) {
                return SwapToken(token: swapToken.token, userWallet: userWallet)
            }
            return SwapToken(token: swapToken.token, userWallet: nil)
        }
        
        // update from Token
        let fromUserWallet: Wallet = userWallets
            .first(where: {
                $0.pubkey == state.fromToken.userWallet?.pubkey &&
                $0.mintAddress == state.fromToken.address
            })
            ??
            userWallets.first(where: {
                $0.mintAddress == PublicKey.usdcMint.base58EncodedString
            })
            ??
            userWallets.first(where: {
                $0.isNativeSOL
            })
            ??
            .nativeSolana(pubkey: nil, lamport: nil)
        
        let fromToken = SwapToken(
            token: fromUserWallet.token,
            userWallet: fromUserWallet
        )
        
        // update toToken
        var toToken: SwapToken
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
        } else if let chosenToToken = autoChooseToToken(for: fromToken, from: state.swapTokens) {
            toToken = chosenToToken
        } else {
            return state.copy(status: .error(reason: .unknown), swapTokens: swapTokens, fromToken: fromToken)
        }
        
        // return state
        return state.copy(swapTokens: swapTokens, fromToken: fromToken, toToken: toToken)
    }
}
