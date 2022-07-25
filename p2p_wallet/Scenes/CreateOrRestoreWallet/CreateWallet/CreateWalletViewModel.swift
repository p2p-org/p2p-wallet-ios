// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

final class CreateWalletViewModel: BaseViewModel {
    let onboardingStateMachine: CreateWalletStateMachine

    init(tKeyFacade: TKeyFacade? = nil) {
        onboardingStateMachine = .init(provider: tKeyFacade ?? TKeyMockupFacade())
    }
}
