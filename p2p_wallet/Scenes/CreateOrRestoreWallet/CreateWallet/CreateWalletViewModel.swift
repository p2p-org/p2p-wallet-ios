// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver

final class CreateWalletViewModel: BaseViewModel {
    let onboardingStateMachine: CreateWalletStateMachine

    init(tKeyFacade: TKeyFacade? = nil) {
        onboardingStateMachine = .init(
            provider: .init(
                authService: AuthServiceBridge(),
                apiGatewayClient: APIGatewayClientImplMock(),
                tKeyFacade: tKeyFacade ?? TKeyMockupFacade(),
                securityStatusProvider: Resolver.resolve()
            )
        )
    }
}

private struct AuthServiceBridge: SocialAuthService {
    @Injected var authService: AuthService

    func auth(type: SocialProvider) async throws -> (tokenID: String, email: String) {
        let authResult = try await authService.socialSignIn(type.socialType)
        return (tokenID: authResult.tokenID, email: authResult.email)
    }
}
