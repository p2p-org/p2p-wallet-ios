//
//  AnyAsyncSequence.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation

struct AnyAsyncSequence<Element>: AsyncSequence {
    typealias AsyncIterator = AnyAsyncIterator<Element>
    typealias Element = Element

    let _makeAsyncIterator: () -> AnyAsyncIterator<Element>

    struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
        typealias Element = Element

        private let _next: () async throws -> Element?

        init<I: AsyncIteratorProtocol>(itr: I) where I.Element == Element {
            var itr = itr
            self._next = {
                try await itr.next()
            }
        }

        mutating func next() async throws -> Element? {
            return try await _next()
        }
    }

    init<S: AsyncSequence>(seq: S) where S.Element == Element {
        self._makeAsyncIterator = {
            AnyAsyncIterator(itr: seq.makeAsyncIterator())
        }
    }

    func makeAsyncIterator() -> AnyAsyncIterator<Element> {
        return _makeAsyncIterator()
    }
}

extension AsyncSequence {
    func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence(seq: self)
    }
}
