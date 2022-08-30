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

    init(initialState: CreateWalletFlowState?) {
        let tKeyFacade: TKeyFacade = available(.mockedTKeyFacade) ?
            TKeyMockupFacade() :
            TKeyJSFacade(
                wkWebView: GlobalWebView.requestWebView(),
                config: .init(
                    metadataEndpoint: String.secretConfig("META_DATA_ENDPOINT") ?? "",
                    torusEndpoint: String.secretConfig("TORUS_ENDPOINT") ?? "",
                    torusNetwork: "testnet",
                    torusVerifierMapping: [
                        "google": String.secretConfig("TORUS_GOOGLE_VERIFIER") ?? "",
                        "apple": String.secretConfig("TORUS_APPLE_VERIFIER") ?? "",
                    ]
                )
            )

        #if !RELEASE
            let apiGatewayEndpoint = String.secretConfig("API_GATEWAY_DEV")!
        #else
            let apiGatewayEndpoint = String.secretConfig("API_GATEWAY_PROD")!
        #endif

        let apiGatewayClient: APIGatewayClient = available(.mockedApiGateway) ?
            APIGatewayClientImplMock() :
            APIGatewayClientImpl(endpoint: apiGatewayEndpoint)

        onboardingStateMachine = .init(
            initialState: initialState,
            provider: .init(
                authService: AuthServiceBridge(),
                apiGatewayClient: apiGatewayClient,
                tKeyFacade: tKeyFacade
            )
        )

        super.init()

        onboardingStateMachine.stateStream.sink { [weak onboardingService] state in
            print(state)
            switch state {
            case let .finish(result):
                switch result {
                case .breakProcess: break
                default: onboardingService?.lastState = nil
                }

            default:
                if state.continuable { onboardingService?.lastState = state }
            }
        }.store(in: &subscriptions)
    }
}
