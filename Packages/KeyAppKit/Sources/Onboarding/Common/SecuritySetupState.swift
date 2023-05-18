// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum SecuritySetupResult: Codable, Equatable {
    case success(data: SecurityData)
}

public enum SecuritySetupEvent {
    case back
    case createPincode
    case confirmPincode(pincode: String)
    case setPincode(pincode: String, isBiometryEnabled: Bool)
}

public struct SecuritySetupContainer { }

public enum SecuritySetupState: Codable, State, Equatable {
    public typealias Event = SecuritySetupEvent
    public typealias Provider = SecuritySetupContainer

    case createPincode
    case confirmPincode(pincode: String)
    case finish(_ result: SecuritySetupResult)

    public private(set) static var initialState: SecuritySetupState = .createPincode

    public func accept(
        currentState: SecuritySetupState,
        event: Event,
        provider _: Provider
    ) async throws -> SecuritySetupState {
        switch currentState {
        case .createPincode:
            switch event {
            case let .confirmPincode(pincode):
                return .confirmPincode(pincode: pincode)
            default:
                throw StateMachineError.invalidEvent
            }
        case .confirmPincode:
            switch event {
            case .back:
                return .createPincode
            case .createPincode:
                return .createPincode
            case let .setPincode(pincode, isBiometryEnabled):
                return .finish(.success(data: SecurityData(pincode: pincode, isBiometryEnabled: isBiometryEnabled)))
            default:
                throw StateMachineError.invalidEvent
            }

        default:
            throw StateMachineError.invalidEvent
        }
    }
}

extension SecuritySetupState: Step, Continuable {
    public var continuable: Bool {
        switch self {
        case .confirmPincode:
            return false
        default:
            return true
        }
    }

    public var step: Float {
        switch self {
        case .createPincode:
            return 1
        case .confirmPincode:
            return 2
        case .finish:
            return 3
        }
    }
}
