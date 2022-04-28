//
// Created by Giang Long Tran on 20.04.2022.
//

import Foundation
import RxSwift

extension ObservableType {
    static func async<T>(_ closure: @escaping () async -> T) -> Observable<T> {
        AsyncStream<T> { continuation in
            Task {
                let value = await closure()
                continuation.yield(value)
                continuation.finish()
            }
        }
        .asObservable()
    }

    static func asyncThrowing(_ closure: @escaping () async throws -> Element) -> Observable<Element> {
        AsyncThrowingStream<Element, Error> { continuation in
            Task {
                do {
                    let value = try await closure()
                    continuation.yield(value)
                    continuation.finish(throwing: nil)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        .asObservable()
    }
}

extension PrimitiveSequenceType where Trait == CompletableTrait, Element == Swift.Never {
    static func asyncThrowing(_ closure: @escaping () async throws -> Void) -> Completable {
        AsyncThrowingStream<Never, Error> { continuation in
            Task {
                do {
                    try await closure()
                    continuation.finish(throwing: nil)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        .asObservable()
        .asCompletable()
    }
}

extension PrimitiveSequenceType where Trait == SingleTrait {
    static func asyncThrowing(_ closure: @escaping () async throws -> Element) -> Single<Element> {
        Observable.asyncThrowing(closure).asSingle()
    }
}
