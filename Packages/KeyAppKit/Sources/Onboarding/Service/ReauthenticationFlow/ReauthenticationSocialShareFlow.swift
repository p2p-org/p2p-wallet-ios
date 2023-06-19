//
//  File.swift
//
//
//  Created by Giang Long Tran on 15/06/2023.
//

import Foundation

public struct ReauthenticationSocialShareResult: Equatable {
    public let torusKey: TorusKey
}

public struct ReauthenticationSocialShareProvider {
    let tkeyFacade: TKeyFacade
    let socialAuthService: SocialAuthService
}

public enum ReauthenticationSocialShareEvent {
    case signIn
    case cancel
}

public enum ReauthenticationSocialShareState: State, Equatable {
    public typealias Event = ReauthenticationSocialShareEvent
    public typealias Provider = ReauthenticationSocialShareProvider

    public static var initialState: Self = .signIn(socialProvider: .google)

    case signIn(socialProvider: SocialProvider)
    case finish(result: ReauthenticationSocialShareResult)
    case cancel

    public func accept(currentState: Self, event: Event, provider: Provider) async throws -> Self {
        switch currentState {
        case .signIn:
            return try await handleEventForSignInState(
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
            let (tokenId, _) = try await provider.socialAuthService.auth(type: socialProvider)

            try await provider.tkeyFacade.initialize()
            let torusKey = try await provider.tkeyFacade
                .obtainTorusKey(
                    tokenID: TokenID(
                        value: tokenId,
                        provider: socialProvider.rawValue
                    )
                )

            return .finish(result: ReauthenticationSocialShareResult(torusKey: torusKey))

        case .cancel:
            return .cancel
        }
    }
}

extension ReauthenticationSocialShareState: Step {
    public var step: Float {
        switch self {
        case .signIn:
            return 1
        default:
            return 0
        }
    }
}
