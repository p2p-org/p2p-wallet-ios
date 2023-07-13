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
    func handleError(_ error: Error, config: ErrorObserverConfig?)

    @available(*, deprecated, message: "Will be removed")
    func handleError(_ error: Error, userInfo: [String: Any]?)
}

public struct ErrorObserverConfig {
    public let domain: String?
    public var flags: Flag

    public init(domain: String? = nil, flags: Flag) {
        self.domain = domain
        self.flags = flags
    }

    public struct Flag: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let realtimeAlert = Flag(rawValue: 1 << 0)
    }
}

public extension ErrorObserver {
    func handleError(_ error: Error) {
        handleError(error, config: nil)
    }

    /// Report error and throw error
    func intercept(_ error: Error, config: ErrorObserverConfig? = nil) -> Error {
        handleError(error, config: config)
        return error
    }

    /// Helper method to handle error in ``AsyncValueState``
    func handleAsyncValue<T>(_ asyncValue: AsyncValue<T>, config: ErrorObserverConfig? = nil) -> AnyCancellable {
        asyncValue
            .statePublisher
            .map(\.error)
            .compactMap { $0 }
            .sink { error in handleError(error, config: config) }
    }
}

public class MockErroObserver: ErrorObserver {
    public init() {}

    public func handleError(_ error: Error, config _: ErrorObserverConfig?) {
        debugPrint(error)
    }

    public func handleError(_ error: Error, userInfo: [String: Any]?) {
        debugPrint(error, userInfo)
    }
}
