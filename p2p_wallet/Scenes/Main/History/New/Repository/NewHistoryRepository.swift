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

    func getAll(account: Account?, mint: String?) -> ItemSequence {
        if let account {
            return ItemSequence(provider: provider, secretKey: account.secretKey, pubKey: account.publicKey.base58EncodedString, mint: mint)
        } else {
            return ItemSequence(provider: provider, secretKey: Data(), pubKey: "", mint: mint)
        }
    }
}

extension NewHistoryServiceRepository {
    struct ItemSequence: AsyncSequence {
        typealias Element = HistoryTransaction

        private var provider: KeyAppHistoryProvider
        private var secretKey: Data
        private var pubKey: String
        private var mint: String?

        init(provider: KeyAppHistoryProvider, secretKey: Data, pubKey: String, mint: String? = nil) {
            self.provider = provider
            self.secretKey = secretKey
            self.pubKey = pubKey
            self.mint = mint
        }

        class AsyncIterator: AsyncIteratorProtocol {
            var provider: KeyAppHistoryProvider
            var secretKey: Data
            var pubKey: String
            var mint: String?

            var fetchable: Bool = true
            var cache: [Element] = []
            var offset = 0
            let limit = 20

            init(provider: KeyAppHistoryProvider, secretKey: Data, pubKey: String, mint: String?) {
                self.provider = provider
                self.secretKey = secretKey
                self.pubKey = pubKey
                self.mint = mint
            }

            func next() async throws -> HistoryTransaction? {
                if cache.isEmpty && fetchable {
                    let result = try await provider.transactions(secretKey: secretKey, pubKey: pubKey, mint: mint, offset: offset, limit: limit)
                    cache.append(contentsOf: result)

                    fetchable = result.count == limit
                    offset += cache.count
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

        func makeAsyncIterator() -> AsyncIterator {
            return AsyncIterator(provider: provider, secretKey: secretKey, pubKey: pubKey, mint: mint)
        }
    }
}
