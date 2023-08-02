//
//  File.swift
//
//
//  Created by Giang Long Tran on 18.07.2023.
//

import Combine
import Foundation
import KeyAppKitCore
@testable import KeyAppBusiness

class MockRealtimeSolanaAccountService: RealtimeSolanaAccountService {
    var owner: String {
        "MockOwner"
    }

    var update: AnyPublisher<SolanaAccount, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    var state: RealtimeSolanaAccountState {
        currentState
    }

    var statePublisher: AnyPublisher<RealtimeSolanaAccountState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private var updateSubject = PassthroughSubject<SolanaAccount, Never>()
    private var stateSubject = PassthroughSubject<RealtimeSolanaAccountState, Never>()
    private var currentState: RealtimeSolanaAccountState = .connecting

    func reconnect(with _: ProxyConfiguration?) {
        // Mock implementation for reconnect
    }

    func connect() {
        // Mock implementation for connect
    }

    // Helper methods to simulate changes in state and update

    func simulateStateChange(_ state: RealtimeSolanaAccountState) {
        currentState = state
        stateSubject.send(state)
    }

    func simulateUpdate(_ account: SolanaAccount) {
        updateSubject.send(account)
    }
}
