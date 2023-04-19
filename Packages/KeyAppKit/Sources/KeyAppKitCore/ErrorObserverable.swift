//
//  File.swift
//
//
//  Created by Giang Long Tran on 10.03.2023.
//

import Combine
import Foundation

/// All services or manager classes should comfort to this protocol.
public protocol ErrorObserver {
    /// Report error
    func handleError(_ error: Error)
}

public extension ErrorObserver {
    func run<T>(code: () throws -> T) throws -> T {
        do {
            return try code()
        } catch {
            handleError(error)
            throw error
        }
    }

    func run<T>(code: () async throws -> T) async throws -> T {
        do {
            return try await code()
        } catch {
            handleError(error)
            throw error
        }
    }

    /// Helper method to handle error in ``AsyncValueState``
    func handleAsyncValue<T>(_ asyncValue: AsyncValue<T>) -> AnyCancellable {
        asyncValue
            .statePublisher
            .map(\.error)
            .compactMap { $0 }
            .sink { error in handleError(error) }
    }
}
