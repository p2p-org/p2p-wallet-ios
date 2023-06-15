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
    func handleError(_ error: Error, userInfo: [String: Any]?)
}

public extension ErrorObserver {
    // Report error and throw error
    func watchError(_ error: Error) -> Error {
        handleError(error)
        return error
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
