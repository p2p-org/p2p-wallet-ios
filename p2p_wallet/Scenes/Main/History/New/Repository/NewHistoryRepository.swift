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

class NewHistoryServiceRepository: Repository {
    typealias Element = HistoryTransaction

    var provider: KeyAppHistoryProvider

    init(provider: KeyAppHistoryProvider) {
        self.provider = provider
    }

    func get(id: Element.ID) async throws {
        fatalError()
    }

    class AsyncIterator: AsyncIteratorProtocol {
        typealias Item = HistoryTransaction

        var provider: KeyAppHistoryProvider
        var secretKey: Data
        var pubKey: String
        var mint: String?

        var fetchable: Bool = true
        var cache: [Item] = []
        var offset = 0
        var limit = 20

        init(provider: KeyAppHistoryProvider, secretKey: Data, pubKey: String, mint: String?) {
            self.provider = provider
            self.secretKey = secretKey
            self.pubKey = pubKey
            self.mint = mint
        }

        func next() async throws -> Item? {
            if cache.isEmpty && fetchable {
                let result = try await provider.transactions(secretKey: secretKey, pubKey: pubKey, mint: mint, offset: offset, limit: limit)
                cache.append(contentsOf: result)

                fetchable = result.count == limit
            }

            if cache.isEmpty && !fetchable {
                return nil
            } else if cache.isEmpty {
                return nil
            } else {
                return cache.removeFirst()
            }
        }
    }

    func getAll(account: Account?, mint: String?) -> AsyncIterator {
        if let account {
            return AsyncIterator(provider: provider, secretKey: account.secretKey, pubKey: account.publicKey.base58EncodedString, mint: mint)
        } else {
            return AsyncIterator(provider: provider, secretKey: Data(), pubKey: "", mint: mint)
        }
    }
}
