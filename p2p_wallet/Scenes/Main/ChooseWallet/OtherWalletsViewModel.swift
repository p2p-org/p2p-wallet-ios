//
//  OtherWalletsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import BECollectionView
import RxSwift

class OtherWalletsViewModel: BEListViewModel<Wallet> {
    let tokensRepository: TokensRepository
    
    init(tokensRepository: TokensRepository) {
        self.tokensRepository = tokensRepository
        super.init()
    }
    
    override func createRequest() -> Single<[Wallet]> {
        Single<[Wallet]>.create {observer in
            DispatchQueue.global(qos: .background).async {
                let wallets = self.tokensRepository.supportedTokens
                    .map {
                        Wallet(pubkey: nil, lamports: nil, token: $0, liquidity: false)
                    }
                    .filter {
                        $0.symbol != "SOL"
                    }
                
                observer(.success(wallets))
            }
            return Disposables.create()
        }
    }
}
