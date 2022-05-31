//
//  Task+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 31/05/2022.
//

import Foundation
import RxSwift

extension Task {
    func asSingle() -> Single<Success> {
        AsyncThrowingStream<Success, Error> { continuation in
            Task<Void, Error> {
                do {
                    let value = try await self.value
                    continuation.yield(value)
                    continuation.finish(throwing: nil)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        .asObservable()
        .asSingle()
    }
}
