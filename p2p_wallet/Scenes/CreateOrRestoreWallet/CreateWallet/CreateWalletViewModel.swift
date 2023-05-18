// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver
import Amplitude

final class CreateWalletViewModel: BaseViewModel, ObservableObject {
    let onboardingStateMachine: CreateWalletStateMachine

    @Injected var onboardingService: OnboardingService

    init(
        initialState: CreateWalletFlowState?,
        provider: OnboardingStateMachineProvider = OnboardingStateMachineProviderImpl()
    ) {
        onboardingStateMachine = .init(
            initialState: initialState,
            provider: .init(
                authService: AuthServiceBridge(),
                apiGatewayClient: Resolver.resolve(),
                tKeyFacade: provider.createTKeyFacade(),
//                deviceName: AMPDeviceInfo().model
                deviceName: ""
            )
        )

        super.init()

        onboardingStateMachine.stateStream.sink { [weak onboardingService] state in
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
