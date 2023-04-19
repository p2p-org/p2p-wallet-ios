// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum SocialSignInResult: Codable, Equatable {
    case successful(
        email: String,
        authProvider: String,
        seedPhrase: String,
        ethPublicKey: String,
        deviceShare: String,
        customShare: String,
        metadata: String
    )
    case breakProcess
    case switchToRestoreFlow(authProvider: SocialProvider, email: String)
}

public enum SocialSignInEvent {
    case signIn(socialProvider: SocialProvider)
    case signInTorus(tokenID: String, email: String, socialProvider: SocialProvider)
    case signInBack
    case restore(authProvider: SocialProvider, email: String)
}

public struct SocialSignInContainer {
    let tKeyFacade: TKeyFacade
    let authService: SocialAuthService
}

public enum SocialSignInState: Codable, State, Equatable {
    public typealias Event = SocialSignInEvent
    public typealias Provider = SocialSignInContainer

    case socialSelection
    case socialSignInProgress(tokenID: String, email: String, socialProvider: SocialProvider)
    case socialSignInAccountWasUsed(signInProvider: SocialProvider, usedEmail: String)
    @available(*, deprecated, message: "This case is deprecated")
    case socialSignInTryAgain(signInProvider: SocialProvider, usedEmail: String)
    case finish(SocialSignInResult)

    public static var initialState: SocialSignInState = .socialSelection

    public func accept(
        currentState: SocialSignInState,
        event: SocialSignInEvent,
        provider: SocialSignInContainer
    ) async throws -> SocialSignInState {
        switch currentState {
        case .socialSelection:
            return try await socialSelectionEventHandler(currentState: currentState, event: event, provider: provider)
        case .socialSignInProgress:
            return try await socialSignInProgressEventHandler(event: event, provider: provider)
        case .socialSignInAccountWasUsed:
            return try await socialSignInAccountWasUsedHandler(
                currentState: currentState,
                event: event,
                provider: provider
            )
        case .socialSignInTryAgain:
            return try await socialTryAgainEventHandler(currentState: currentState, event: event, provider: provider)
        case .finish:
            throw StateMachineError.invalidEvent
        }
    }

    internal func socialSelectionEventHandler(
        currentState _: Self, event: Event,
        provider: Provider
    ) async throws -> Self {
        switch event {
        case let .signIn(socialProvider):
            let (value, email) = try await provider.authService.auth(type: socialProvider)
            return .socialSignInProgress(tokenID: value, email: email, socialProvider: socialProvider)
        case .signInBack:
            return .finish(.breakProcess)
        default:
            throw StateMachineError.invalidEvent
        }
    }

    internal func socialSignInProgressEventHandler(event: Event, provider: Provider) async throws -> Self {
        switch event {
        case let .signInTorus(value, email, socialProvider):
            let tokenID = TokenID(value: value, provider: socialProvider.rawValue)

            do {
                try await provider.tKeyFacade.initialize()
                let torusKey = try await provider.tKeyFacade.obtainTorusKey(tokenID: tokenID)
                let result = try await provider.tKeyFacade
                    .signUp(
                        torusKey: torusKey,
                        privateInput: Mnemonic().phrase.joined(separator: " ")
                    )

                return .finish(
                    .successful(
                        email: email,
                        authProvider: socialProvider.rawValue,
                        seedPhrase: result.privateSOL,
                        ethPublicKey: result.reconstructedETH,
                        deviceShare: result.deviceShare,
                        customShare: result.customShare,
                        metadata: result.metaData
                    )
                )
            } catch let error as TKeyFacadeError {
                switch error.code {
                case 1009:
                    return .socialSignInAccountWasUsed(signInProvider: socialProvider, usedEmail: email)
                default:
                    throw error
                }
            }
        case .signInBack:
            return .socialSelection
        default:
            throw StateMachineError.invalidEvent
        }
    }

    internal func socialTryAgainEventHandler(
        currentState _: Self, event: Event,
        provider: Provider
    ) async throws -> Self {
        switch event {
        case let .signIn(socialProvider):
            let (value, email) = try await provider.authService.auth(type: socialProvider)
            let tokenID = TokenID(value: value, provider: socialProvider.rawValue)
            do {
                let torusKey = try await provider.tKeyFacade.obtainTorusKey(tokenID: tokenID)
                let result = try await provider
                    .tKeyFacade
                    .signUp(
                        torusKey: torusKey,
                        privateInput: Mnemonic().phrase.joined(separator: " ")
                    )

                return .finish(
                    .successful(
                        email: email,
                        authProvider: socialProvider.rawValue,
                        seedPhrase: result.privateSOL,
                        ethPublicKey: result.reconstructedETH,
                        deviceShare: result.deviceShare,
                        customShare: result.customShare,
                        metadata: result.metaData
                    )
                )
            } catch let error as TKeyFacadeError {
                switch error.code {
                case 1009:
                    return .socialSignInAccountWasUsed(signInProvider: socialProvider, usedEmail: email)
                default:
                    throw error
                }
            }
        case .signInBack:
            return .finish(.breakProcess)
        default:
            throw StateMachineError.invalidEvent
        }
    }

    internal func socialSignInAccountWasUsedHandler(
        currentState: Self, event: Event,
        provider: Provider
    ) async throws -> Self {
        switch event {
        case .signIn:
            return try await socialSelectionEventHandler(currentState: currentState, event: event, provider: provider)
        case let .restore(signInProvider, email):
            return .finish(.switchToRestoreFlow(authProvider: signInProvider, email: email))
        case .signInBack:
            return .socialSelection
        default:
            throw StateMachineError.invalidEvent
        }
    }
}

extension SocialSignInState: Step, Continuable {
    public var continuable: Bool { false }

    public var step: Float {
        switch self {
        case .socialSelection:
            return 1
        case .socialSignInProgress:
            return 2
        case .socialSignInAccountWasUsed:
            return 3
        case .socialSignInTryAgain:
            return 4
        case .finish:
            return 5
        }
    }
}
