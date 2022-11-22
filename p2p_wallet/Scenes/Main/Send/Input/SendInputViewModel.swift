// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import Send

class SendInputViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()

    let stateMachine: SendInputStateMachine

    @Published var state: SendInputState

    init(recipient: Recipient) {
        let state = SendInputState.zero(
            recipient: recipient,
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: .init(wallets: [], exchangeRate: [:])
        )

        self.state = state
        stateMachine = .init(initialState: state, services: .init(swapService: MockedSwapService(result: nil)))

        stateMachine.statePublisher
            .sink { [weak self] in self?.state = $0 }
            .store(in: &subscriptions)
    }
}
