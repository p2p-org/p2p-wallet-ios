//
//  PaginatedAsyncSequence.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 20.02.2023.
//

import Foundation

struct PaginatedAsyncSequence<Element>: AsyncSequence {
    typealias Element = Element
    typealias FetchFn = (_ offset: Int, _ limit: Int) async throws -> [Element]
    
    let fetchFn: FetchFn
    
    class AsyncIterator: AsyncIteratorProtocol {
        let fetchFn: FetchFn
        var fetchable: Bool = true
        var cache: [Element] = []
        var offset = 0
        let limit = 20

        init(fetchFn: @escaping FetchFn) {
            self.fetchFn = fetchFn
        }

        func next() async throws -> Element? {
            if cache.isEmpty && fetchable {
                let result = try await fetchFn(offset, limit)
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
        return AsyncIterator(fetchFn: fetchFn)
    }
}
