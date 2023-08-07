import Foundation

public struct AnyAsyncSequence<Element>: AsyncSequence {
    public typealias AsyncIterator = AnyAsyncIterator<Element>
    public typealias Element = Element

    public let _makeAsyncIterator: () -> AnyAsyncIterator<Element>

    public struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
        public typealias Element = Element

        private let _next: () async throws -> Element?

        public init<I: AsyncIteratorProtocol>(itr: I) where I.Element == Element {
            var itr = itr
            _next = {
                try await itr.next()
            }
        }

        public mutating func next() async throws -> Element? {
            try await _next()
        }
    }

    public init<S: AsyncSequence>(seq: S) where S.Element == Element {
        _makeAsyncIterator = {
            AnyAsyncIterator(itr: seq.makeAsyncIterator())
        }
    }

    public func makeAsyncIterator() -> AnyAsyncIterator<Element> {
        _makeAsyncIterator()
    }
}

public extension AsyncSequence {
    func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence(seq: self)
    }
}
