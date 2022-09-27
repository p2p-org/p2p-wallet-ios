// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Amplitude
import Combine
import Foundation
import Onboarding
import Resolver

final class CreateWalletViewModel: BaseViewModel {
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
                deviceName: Device.getDeviceNameFromIdentifier(AMPDeviceInfo().model)
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
