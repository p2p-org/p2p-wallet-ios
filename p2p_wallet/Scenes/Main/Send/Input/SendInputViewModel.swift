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
        let state = SendInputState(
            status: .ready,
            recipient: recipient,
            userTokenAccount: .nativeSolana(pubkey: "", lamport: 100),
            userWalletState: .init(wallets: [], exchangeRate: [:]),
            amountInFiat: 0,
            amountInToken: 0,
            fee: .zero
        )

        self.state = state
        stateMachine = .init(initialState: state)

        stateMachine.statePublisher
            .sink { [weak self] in self?.state = $0 }
            .store(in: &subscriptions)
    }
}
