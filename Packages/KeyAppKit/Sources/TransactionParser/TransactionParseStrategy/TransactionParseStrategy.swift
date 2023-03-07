// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A parse strategy
public protocol TransactionParseStrategy: AnyObject {
  /// Check is current parsing strategy can handle this transaction
  func isHandlable(with transactionInfo: TransactionInfo) -> Bool

  /// Parse a transaction
  func parse(
    _ transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> AnyHashable?
}
