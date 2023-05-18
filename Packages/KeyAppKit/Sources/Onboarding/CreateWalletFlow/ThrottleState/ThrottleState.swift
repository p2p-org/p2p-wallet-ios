// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

struct ThrottleConfiguration {
    let maxCount: Int
    let interval: TimeInterval
    let overheatInterval: TimeInterval
}

enum ThrottleEvent {
    case heat
    case cooling
}

enum ThrottleError: Error {
    case overheating(until: Date)
}

enum ThrottleState: Codable, State, Equatable {
    public typealias Event = ThrottleEvent
    public typealias Provider = ThrottleConfiguration

    public private(set) static var initialState: ThrottleState = .cold(count: 0, start: Date())

    case cold(count: Int, start: Date)
    case overheat(until: Date)

    func accept(
        currentState: ThrottleState,
        event: ThrottleEvent,
        provider: ThrottleConfiguration
    ) async throws -> ThrottleState {
        switch self {
        case let .cold(count, start):
            switch event {
            case .cooling:
                if start.addingTimeInterval(provider.interval) > Date() {
                    return .cold(count: 0, start: Date())
                } else {
                    return currentState
                }
            case .heat:
                if start.addingTimeInterval(provider.interval) > Date() {
                    return .cold(count: 1, start: Date())
                } else {
                    if count + 1 > provider.maxCount {
                        return .overheat(until: Date().addingTimeInterval(provider.interval))
                    } else {
                        return .cold(count: count + 1, start: start)
                    }
                }
            }
        case let .overheat(until):
            switch event {
            case .cooling:
                if Date() > until {
                    return .cold(count: 0, start: Date())
                } else {
                    throw ThrottleError.overheating(until: until)
                }
            case .heat:
                if Date() > until {
                    return .cold(count: 1, start: Date())
                } else {
                    throw ThrottleError.overheating(until: until)
                }
            default:
                throw StateMachineError.invalidEvent
            }
        }
    }
}
