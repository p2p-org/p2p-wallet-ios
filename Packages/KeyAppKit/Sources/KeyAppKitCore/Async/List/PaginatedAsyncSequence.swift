//
//  PaginatedAsyncSequence.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 20.02.2023.
//

import Foundation

public struct PaginatedAsyncSequence<Element>: AsyncSequence {
    public typealias Element = Element
    public typealias FetchFn = (_ offset: Int, _ limit: Int) async throws -> [Element]

    public let limit: Int
    public let fetchFn: FetchFn

    public init(limit: Int = 20, fetchFn: @escaping FetchFn) {
        self.fetchFn = fetchFn
        self.limit = limit
    }

    public class AsyncIterator: AsyncIteratorProtocol {
        public let fetchFn: FetchFn
        public var fetchable: Bool = true
        public var cache: [Element] = []
        public var offset: Int = 0
        public let limit: Int

        public init(fetchFn: @escaping FetchFn, limit: Int) {
            self.fetchFn = fetchFn
            self.limit = limit
        }

        public func next() async throws -> Element? {
            if cache.isEmpty && fetchable {
                let result = try await fetchFn(offset, limit)
                if Task.isCancelled { return nil }

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

    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(fetchFn: fetchFn, limit: limit)
    }
}
