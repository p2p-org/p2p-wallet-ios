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
    ) async -> JupiterSwapState {
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
            return state.modified {
                $0.status = .error(reason: .unknown)
                $0.swapTokens = swapTokens
                $0.fromToken = fromToken
            }
        }
        
        // if from and to token stay unchanged, update only the token with new balance, not the route
        if fromToken.address == state.fromToken.address &&
            toToken.address == state.toToken.address
        {
            return state.modified {
                $0.swapTokens = swapTokens
                $0.fromToken = fromToken
                $0.toToken = toToken
            }
        }
        
        // otherwise update the route also
        let state = state.modified {
            $0.swapTokens = swapTokens
            $0.fromToken = fromToken
            $0.toToken = toToken
        }
        return await calculateRoute(state: state, services: services)
    }
}
