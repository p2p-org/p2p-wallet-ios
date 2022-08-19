// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver

final class CreateWalletViewModel: BaseViewModel {
    let onboardingStateMachine: CreateWalletStateMachine

    @Injected var onboardingService: OnboardingService

    init(tKeyFacade: TKeyFacade? = nil, initialState: CreateWalletFlowState?) {
        onboardingStateMachine = .init(
            initialState: initialState,
            provider: .init(
                authService: AuthServiceBridge(),
                apiGatewayClient: APIGatewayClientImplMock(),
                // apiGatewayClient: APIGatewayClientImpl(endpoint: String.secretConfig("API_GATEWAY")!),
                tKeyFacade: tKeyFacade ?? TKeyMockupFacade(),
                securityStatusProvider: Resolver.resolve()
            )
        )

        super.init()

        onboardingStateMachine.stateStream.sink { [weak onboardingService] state in
            switch state {
            case .finish:
                onboardingService?.lastState = nil
            default:
                if state.continuable { onboardingService?.lastState = state }
            }
        }.store(in: &subscriptions)
    }
}

private struct AuthServiceBridge: SocialAuthService {
    @Injected var authService: AuthService

    func auth(type: SocialProvider) async throws -> (tokenID: String, email: String) {
        let authResult = try await authService.socialSignIn(type.socialType)
        return (tokenID: authResult.tokenID, email: authResult.email)
    }
}
