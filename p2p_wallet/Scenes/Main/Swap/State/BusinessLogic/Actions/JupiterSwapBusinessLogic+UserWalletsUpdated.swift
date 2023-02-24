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
        } else {
            toToken = try JupiterSwapBusinessLogic.autoChooseToToken(for: fromToken, from: state.swapTokens)
        }
        
        return state.copy(fromToken: fromToken, toToken: toToken)
    }
}
