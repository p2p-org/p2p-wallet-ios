//
//  NewHistoryRepository.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.02.2023.
//

import Foundation
import History
import Resolver
import SolanaSwift
import KeyAppKitCore

class HistoryRepository: Repository {
    typealias Element = HistoryTransaction

    var provider: KeyAppHistoryProvider

    init(provider: KeyAppHistoryProvider) {
        self.provider = provider
    }

    func get(id: Element.ID) async throws {
        fatalError()
    }

    func getAll(account: KeyPair?, mint: String?) -> AnyAsyncSequence<Element> {
        let secretKey = account?.secretKey ?? Data()
        let pubKey = account?.publicKey.base58EncodedString ?? ""

        return PaginatedAsyncSequence { [provider] offset, limit in
            try await provider.transactions(secretKey: secretKey, pubKey: pubKey, mint: mint, offset: offset, limit: limit)
        }
        .eraseToAnyAsyncSequence()
    }
}
