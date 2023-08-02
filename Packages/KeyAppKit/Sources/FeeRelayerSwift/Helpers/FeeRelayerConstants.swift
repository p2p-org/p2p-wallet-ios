// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public struct FeeRelayerConstants {
    /// A default slippage value for top up operation.
    ///
    /// When user uses spl token as fee payer, fee relayer service will swap fee amount for transaction in this token to native token (SOL).
    /// In some cases if the swapping amount is to small, user can receive slippage error.
    static let topUpSlippage: Double = 0.03
}
