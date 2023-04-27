//
//  File.swift
//
//
//  Created by Giang Long Tran on 27.04.2023.
//

import Combine
import Foundation
import KeyAppKitCore

/// The service state.
enum SolanaRealtimeAccountState {
    /// Service was created.
    case initialising

    /// Service is connecting.
    case connecting

    /// Service operates normally.
    case running

    /// Service stop working with reason.
    case stop(reason: Error)
}

/// The service for monitoring native account and SPL accounts associated with user's wallet.
protocol SolanaRealtimeAccountService {
    /// User wallet public key
    var account: String { get }

    var state: SolanaRealtimeAccountState { get }

    /// Updating stream
    ///
    /// Service emits accounts state when is running first time or socket receive new update.
    var update: AnyPublisher<SolanaAccount, Never> { get }

    func start()

    func stop()
}
