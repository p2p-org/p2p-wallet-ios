// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import TransactionParser
import XCTest

struct ParseStrategyUtils {
  enum Error: Swift.Error {
    case invalidClass
  }

  static func readTransaction(at path: String) -> TransactionInfo {
    Bundle.module.decode(TransactionInfo.self, from: path)
  }

  /// Automatic parsing
  static func parse<T>(
    at path: String,
    strategy: TransactionParseStrategy,
    configuration: Configuration
  ) async throws -> T? {
    let trx = readTransaction(at: path)

    // Parse
    let parsedTransaction = try await strategy.parse(
      trx,
      config: configuration
    )

    guard let parsedTransaction = parsedTransaction else { return nil }
    guard let parsedTransaction = parsedTransaction as? T else { throw Error.invalidClass }

    return parsedTransaction
  }
}
