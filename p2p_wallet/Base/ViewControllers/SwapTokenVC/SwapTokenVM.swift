//
//  SwapTokenVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

struct SwapPair {
    let from: SolanaSDK.Token
    let to: SolanaSDK.Token
}

class SwapTokenVM {
    let walletsVM = WalletsVM.ofCurrentUser
    var pools: Single<[SolanaSDK.Pool]> {
        SolanaSDK.shared.getSwapPools()
    }
    var availableSwapPairs: Single<[SwapPair]> {
        pools.map {pools in
            if var supportedTokens = SolanaSDK.Token.getSupportedTokens(network: Defaults.network)
            {
                // Add WSOL
                supportedTokens.append(
                    SolanaSDK.Token(
                        name: "Wrapped Solana",
                        mintAddress: SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString,
                        pubkey: nil,
                        symbol: "SOL",
                        icon: nil,
                        amount: nil,
                        decimals: nil
                    )
                )
                
                // get SwapPairs
                var pairs = [SwapPair]()
                for pool in pools {
                    if let tokenA = supportedTokens.first(where: {$0.mintAddress == pool.swapData.mintA.base58EncodedString}),
                       let tokenB = supportedTokens.first(where: {$0.mintAddress == pool.swapData.mintB.base58EncodedString})
                    {
                        pairs.append(SwapPair(from: tokenA, to: tokenB))
                    }
                }
                return pairs
            }
            return []
        }
    }
    
    func findSwapPair(fromWallet: Wallet?, toWallet: Wallet?) -> Single<SwapPair?> {
        availableSwapPairs
            .map {$0.first(where: {
                $0.from.mintAddress == fromWallet?.mintAddress &&
                    $0.to.mintAddress == toWallet?.mintAddress
            })}
    }
}
