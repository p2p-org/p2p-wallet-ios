// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import KeyAppKitCore

/// The service state.
enum SolanaRealtimeAccountState {
    /// Service was created.
    case initialising

    /// Service is connecting.
    case connecting

    /// Service operates normally.
    case running

    /// Service stop working with a reason.
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
