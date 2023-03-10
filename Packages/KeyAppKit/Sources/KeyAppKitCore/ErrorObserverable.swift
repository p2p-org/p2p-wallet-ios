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
    func handleError(_ error: Error)
}

public extension ErrorObserver {
    func handleAsyncValue<T>(_ publisher: some Publisher<AsyncValueState<T>, Never>) -> AnyCancellable {
        publisher
            .map(\.error)
            .compactMap { $0 }
            .sink { error in handleError(error) }
    }
}
