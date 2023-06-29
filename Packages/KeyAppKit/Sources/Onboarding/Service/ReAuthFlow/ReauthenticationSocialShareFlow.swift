//
//  File.swift
//
//
//  Created by Giang Long Tran on 15/06/2023.
//

import Foundation

public struct ReAuthSocialShareResult: Equatable {
    public let torusKey: TorusKey
}

public struct ReAuthSocialShareProvider {
    let tkeyFacade: TKeyFacade
    let socialAuthService: SocialAuthService
    let expectedEmail: String
}

public enum ReAuthSocialShareEvent {
    case signIn
    case cancel
    case back
}

public enum ReAuthSocialShareState: State, Equatable {
    public typealias Event = ReAuthSocialShareEvent
    public typealias Provider = ReAuthSocialShareProvider

    public static var initialState: Self = .signIn(socialProvider: .google)

    case signIn(socialProvider: SocialProvider)
    case wrongAccount(socialProvider: SocialProvider, wrongEmail: String)
    case finish(result: ReAuthSocialShareResult)
    case cancel

    public func accept(currentState: Self, event: Event, provider: Provider) async throws -> Self {
        switch currentState {
        case .signIn:
            return try await handleEventForSignInState(
                state: currentState,
                event: event,
                provider: provider
            )

        case .wrongAccount:
            return try await handleEventForWrongAccount(
                state: currentState,
                event: event,
                provider: provider
            )

        case .finish:
            return currentState

        case .cancel:
            return currentState
        }
    }

    func handleEventForWrongAccount(
        state: Self,
        event: Event,
        provider _: Provider
    ) async throws -> Self {
        guard case let .wrongAccount(socialProvider, _) = state else {
            throw StateMachineError.invalidState
        }

        switch event {
        case .cancel:
            return .cancel

        case .signIn:
            return self

        case .back:
            return .signIn(socialProvider: socialProvider)
        }
    }

    func handleEventForSignInState(
        state: Self,
        event: Event,
        provider: Provider
    ) async throws -> Self {
        guard case let .signIn(socialProvider) = state else {
            throw StateMachineError.invalidState
        }

        switch event {
        case .signIn:
            let (tokenId, email) = try await provider.socialAuthService.auth(type: socialProvider)

            if email != provider.expectedEmail {
                return .wrongAccount(socialProvider: socialProvider, wrongEmail: email)
            }

            try await provider.tkeyFacade.initialize()
            let torusKey = try await provider.tkeyFacade
                .obtainTorusKey(
                    tokenID: TokenID(
                        value: tokenId,
                        provider: socialProvider.rawValue
                    )
                )

            return .finish(result: ReAuthSocialShareResult(torusKey: torusKey))

        case .back:
            return .cancel

        case .cancel:
            return .cancel
        }
    }
}

extension ReAuthSocialShareState: Step {
    public var step: Float {
        switch self {
        case .signIn:
            return 1
        case .wrongAccount:
            return 2
        default:
            return 0
        }
    }
}
