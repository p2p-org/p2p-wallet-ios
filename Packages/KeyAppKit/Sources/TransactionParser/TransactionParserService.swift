// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// An additional parsing configuration
public struct Configuration {
  /// An optional account address that is responsible for this transaction.
  let accountView: String?

  /// An optional token symbol that is responsible for this transaction.
  let symbolView: String?

  /// A optional account addresses that covert a fee for this transaction.
  let feePayers: [String]
  
  public init(accountView: String?, symbolView: String?, feePayers: [String]) {
    self.accountView = accountView
    self.symbolView = symbolView
    self.feePayers = feePayers
  }
}

/// The interface that is responsible for parsing raw transaction into user-friendly transaction.
///
/// The user-friendly transactions are easier to read and displaying to end users.
public protocol TransactionParserService {
  /// Parses a raw transaction
  ///
  /// - Parameters:
  ///   - transactionInfo: a raw transaction from SolanaSwift.
  ///   - configuration: a additional configuration that improve parsing accuracy.
  /// - Returns: a user-friendly parsed transaction
  func parse(_ transactionInfo: TransactionInfo, config configuration: Configuration) async throws -> ParsedTransaction
}
