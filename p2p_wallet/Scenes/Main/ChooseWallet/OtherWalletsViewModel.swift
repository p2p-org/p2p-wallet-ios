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
        tokensRepository.getTokensList()
            .map {$0.excludingSpecialTokens()}
            .map {
                $0
                    .filter {
                        $0.symbol != "SOL"
                    }
                    .map {
                        Wallet(pubkey: nil, lamports: nil, token: $0)
                    }
                    
            }
    }
}
