// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum RestoreSeedResult: Codable, Equatable {
    case successful(phrase: [String], path: DerivablePath)
    case back
}

public enum RestoreSeedEvent {
    case back
    case signInWithSeed
    case chooseDerivationPath(phrase: [String])
    case restoreWithSeed(phrase: [String], path: DerivablePath)
}

public struct RestoreSeedContainer { }

public enum RestoreSeedState: Codable, State, Equatable {
    public typealias Event = RestoreSeedEvent
    public typealias Provider = RestoreSeedContainer

    case signInSeed
    case chooseDerivationPath(phrase: [String])
    case finish(result: RestoreSeedResult)

    public static var initialState: RestoreSeedState = .signInSeed

    public func accept(
        currentState: RestoreSeedState,
        event: RestoreSeedEvent,
        provider: RestoreSeedContainer
    ) async throws -> RestoreSeedState {

        switch currentState {
        case .signInSeed:
            switch event {
            case let .chooseDerivationPath(phrase):
                return .chooseDerivationPath(phrase: phrase)
            case .back:
                return .finish(result: .back)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .chooseDerivationPath(phrase):
            switch event {
            case let .restoreWithSeed(phrase, path):
                return .finish(result: .successful(phrase: phrase, path: path))
            case .back:
                return .signInSeed
            default:
                throw StateMachineError.invalidEvent
            }

        default:
            throw StateMachineError.invalidEvent
        }
    }
}

extension RestoreSeedState: Step, Continuable {
    public var continuable: Bool { true }

    public var step: Float {
        switch self {
        case .signInSeed:
            return 1
        case .chooseDerivationPath:
            return 2
        case .finish:
            return 3
        }
    }
}
