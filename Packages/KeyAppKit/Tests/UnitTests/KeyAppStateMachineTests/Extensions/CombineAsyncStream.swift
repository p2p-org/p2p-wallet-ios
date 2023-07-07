import Foundation
import Combine

class CombineAsyncStream<Upstream: Publisher>: AsyncSequence {
    typealias Element = Upstream.Output
    typealias AsyncIterator = CombineAsyncStream<Upstream>
    
    func makeAsyncIterator() -> Self {
        return self
    }
    
    private let stream:
    AsyncThrowingStream<Upstream.Output, Error>
    
    private lazy var iterator = stream.makeAsyncIterator()
    
    private var cancellable: AnyCancellable?
    public init(_ upstream: Upstream) {
        var subscription: AnyCancellable? = nil
        
        stream = AsyncThrowingStream<Upstream.Output, Error>(Upstream.Output.self) { continuation in
            subscription = upstream
                .handleEvents(
                    receiveCancel: {
                        continuation.finish(throwing: nil)
                    }
                )
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    case .finished: continuation.finish(throwing: nil)
                    }
                }, receiveValue: { value in
                    continuation.yield(value)
                })
        }
        
        cancellable = subscription
    }
    
    func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }
}

extension CombineAsyncStream: AsyncIteratorProtocol {
    public func next() async throws -> Upstream.Output? {
        return try await iterator.next()
    }
}

extension Publisher {
    func asyncStream() -> CombineAsyncStream<Self> {
        return CombineAsyncStream(self)
    }
}
