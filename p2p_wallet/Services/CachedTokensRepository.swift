//
//  CachedTokensRepository.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 04.02.2022.
//

import Resolver
import SolanaSwift
import RxSwift

final class CachedTokensRepository: TokensRepository {
    @Injected private var tokensRepository: TokensRepository

    private var cache: [SolanaSDK.Token]?

    func getTokensList() -> Single<[SolanaSDK.Token]> {
        guard let cache = cache else {
            return tokensRepository.getTokensList()
                .do(onSuccess: {[weak self] in
                    self?.cache = $0
                })
        }

        return .just(cache)
    }
}
