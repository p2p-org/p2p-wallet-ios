import Combine
import Foundation

enum AsyncError: Error {
    case finishedWithoutValue
}

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finishedWithoutValue = true
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(throwing: AsyncError.finishedWithoutValue)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(value))
                }
        }
    }
}

extension Publisher {
    typealias Pairwise<T> = (previous: T?, current: T)

    /// Includes the current element as well as the previous element from the upstream publisher in a tuple where the
    /// previous element is optional.
    /// The first time the upstream publisher emits an element, the previous element will be `nil`.
    ///
    /// ```
    /// let range = (1...5)
    /// let subscription = range.publisher
    ///   .pairwise()
    ///   .sink { print("(\($0.previous), \($0.current))", terminator: " ") }
    /// ```
    /// Prints: "(nil, 1) (Optional(1), 2) (Optional(2), 3) (Optional(3), 4) (Optional(4), 5)".
    ///
    /// - Returns: A publisher of a tuple of the previous and current elements from the upstream publisher.
    ///
    /// - Note: Based on <https://stackoverflow.com/a/67133582/3532505>.
    func pairwise() -> AnyPublisher<Pairwise<Output>, Failure> {
        // `scan()` needs an initial value, which is `nil` in our case.
        // Therefore we have to return an optional here and use `compactMap()` below the remove the optional type.
        scan(nil) { previousPair, currentElement -> Pairwise<Output>? in
            Pairwise(previous: previousPair?.current, current: currentElement)
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }
}

// MARK: - deallocatedPublisher

var deinitCallbackKey = "deallocatedPublisher"

extension NSObject {
    func deallocatedPublisher() -> AnyPublisher<Void, Never> {
        synchronized {
            NSObject.deinitCallback(forObject: self)
        }
    }

    fileprivate static func deinitCallback(forObject object: NSObject) -> AnyPublisher<Void, Never> {
        if let deinitCallback = objc_getAssociatedObject(object, &deinitCallbackKey) as? DeinitCallback {
            return deinitCallback.subject.eraseToAnyPublisher()
        }
        let rem = DeinitCallback()
        objc_setAssociatedObject(object, &deinitCallbackKey, rem, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return rem.subject.eraseToAnyPublisher()
    }
}

extension NSObject {
    func synchronized<T>(_ action: () -> T) -> T {
        objc_sync_enter(self)
        let result = action()
        objc_sync_exit(self)
        return result
    }
}

@objc private class DeinitCallback: NSObject {
    let subject = PassthroughSubject<Void, Never>()

    override init() {}

    deinit {
        self.subject.send()
        self.subject.send(completion: .finished)
    }
}
