// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class CloseAccountParseStrategyTests: XCTestCase {
  lazy var tokensRepository = MockTokensRepository()
  lazy var strategy = CloseAccountParseStrategy(tokensRepository: tokensRepository)

  func testCloseAccountParsing() async throws {
    let trx: CloseAccountInfo = try await ParseStrategyUtils.parse(
      at: "trx-close-account-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    // Tests
    XCTAssertEqual(trx.reimbursedAmount, 0.00203928)
    XCTAssertEqual(trx.closedWallet?.pubkey, "8jpWBKSoU7SXz9gJPJS53TEXXuWcg1frXLEdnfomxLwZ")
    XCTAssertEqual(trx.closedWallet?.token.symbol, "soETH")
  }
}
