// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Amplitude
import Combine
import Foundation
import Onboarding
import Resolver

final class CreateWalletViewModel: BaseViewModel, ObservableObject {
    let onboardingStateMachine: CreateWalletStateMachine

    @Injected var onboardingService: OnboardingService

    init(
        initialState: CreateWalletFlowState?,
        provider: OnboardingStateMachineProvider = OnboardingStateMachineProviderImpl()
    ) {
        // Extract device name
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingUTF8: ptr)
            }
        }

        onboardingStateMachine = .init(
            initialState: initialState,
            provider: .init(
                authService: Resolver.resolve(),
                apiGatewayClient: Resolver.resolve(),
                tKeyFacade: provider.createTKeyFacade(),
                deviceName: modelCode ?? ""
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
