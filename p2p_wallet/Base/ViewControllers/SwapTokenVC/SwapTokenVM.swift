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
    let pool: SolanaSDK.Pool
}

class SwapTokenVM {
    let walletsVM = WalletsVM.ofCurrentUser
    var availableSwapPairs = [SwapPair]()
    var currentSwapPair: SwapPair?
    let disposeBag = DisposeBag()
    var sourceWallet = BehaviorRelay<Wallet?>(value: nil)
    var destinationWallet = BehaviorRelay<Wallet?>(value: nil)
    var slippage = BehaviorRelay<Double>(value: 0.1)
    
    init() {
        SolanaSDK.shared.getSwapPools()
            .subscribe(onSuccess: { (pools) in
                self.getSwapPairs(pools: pools)
            })
            .disposed(by: disposeBag)
    }
    
    func findSwapPair(fromWallet: Wallet?, toWallet: Wallet?) -> SwapPair? {
        currentSwapPair = availableSwapPairs
            .first(where: {
                $0.from.mintAddress == fromWallet?.mintAddress &&
                    $0.to.mintAddress == toWallet?.mintAddress
            })
        return currentSwapPair
    }
    
    func getSwapPairs(pools: [SolanaSDK.Pool]) {
        DispatchQueue.global(qos: .background).async {
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
                        pairs.append(SwapPair(from: tokenA, to: tokenB, pool: pool))
                    }
                }
                self.availableSwapPairs = pairs
            }
        }
    }
}
