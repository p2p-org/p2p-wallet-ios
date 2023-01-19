// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Reachability
import Resolver

public extension Reachability {
    static var reachabilityChanged: AnyPublisher<Reachability, Never> {
        NotificationCenter.default.publisher(for: Notification.Name.reachabilityChanged)
            .compactMap { $0.object as? Reachability }
            .eraseToAnyPublisher()
    }

    static var status: AnyPublisher<Reachability.Connection, Never> {
        reachabilityChanged
            .map(\.connection)
            .eraseToAnyPublisher()
    }

    static var isReachable: AnyPublisher<Bool, Never> {
        reachabilityChanged
            .map { $0.connection != .unavailable }
            .eraseToAnyPublisher()
    }

    static var isConnected: AnyPublisher<Void, Never> {
        isReachable
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    static var isDisconnected: AnyPublisher<Void, Never> {
        isReachable
            .filter { !$0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

public extension Reachability {
    var reachabilityChanged: AnyPublisher<Reachability, Never> {
        NotificationCenter.default.publisher(for: Notification.Name.reachabilityChanged)
            .compactMap { $0.object as? Reachability }
            .eraseToAnyPublisher()
    }

    var status: AnyPublisher<Reachability.Connection, Never> {
        reachabilityChanged
            .map(\.connection)
            .eraseToAnyPublisher()
    }

    var isReachable: AnyPublisher<Bool, Never> {
        reachabilityChanged
            .map { $0.connection != .unavailable }
            .eraseToAnyPublisher()
    }

    var isConnected: AnyPublisher<Void, Never> {
        isReachable
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    var isDisconnected: AnyPublisher<Void, Never> {
        isReachable
            .filter { !$0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

public extension Reachability {
    func check() -> Bool {
        print(connection)
        switch connection {
        case .unavailable:
            Resolver.resolve(NotificationService.self).showToast(title: "☕️", text: L10n.YouReOffline.keepCalm)
            return false
        default:
            return true
        }
    }
}
