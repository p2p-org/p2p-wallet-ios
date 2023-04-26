// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A strategy for parsing fee.
public protocol FeeParseStrategy {
  /// Retrieves transaction fee.
  ///
  /// - Parameters:
  ///   - transactionInfo: raw transaction
  ///   - feePayers: a additional fee payer addresses
  /// - Returns: fee
  func calculate(transactionInfo: TransactionInfo, feePayers: [String]) async throws -> FeeAmount
}
