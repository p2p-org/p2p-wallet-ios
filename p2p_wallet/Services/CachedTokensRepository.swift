//
//  CachedTokensRepository.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 04.02.2022.
//

import Resolver
import RxSwift
import SolanaSwift

actor CachedTokensRepository: SolanaTokensRepository {
    @Injected private var tokensRepository: TokensRepository

    private var cache: Set<Token>?

    func getTokensList(useCache _: Bool) async throws -> Set<Token> {
        guard let cache = cache else {
            return try await tokensRepository.getTokensList()
        }
        return cache
    }
}
