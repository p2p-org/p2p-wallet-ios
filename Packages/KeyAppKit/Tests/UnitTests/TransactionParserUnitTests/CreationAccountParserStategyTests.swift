// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class AccountCreationParseStrategyTests: XCTestCase {
  lazy var tokensRepository = MockTokensRepository()
  lazy var strategy = CreationAccountParseStrategy(tokensRepository: tokensRepository)

  func testCreateAccountParsing() async throws {
    let trx: CreateAccountInfo = try await ParseStrategyUtils.parse(
      at: "trx-create-account-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.fee, 0.00203928)
    XCTAssertEqual(trx.newWallet?.token.symbol, "soETH")
    XCTAssertEqual(trx.newWallet?.pubkey, "8jpWBKSoU7SXz9gJPJS53TEXXuWcg1frXLEdnfomxLwZ")
  }

  func testCreateBOPAccountParsing() async throws {
    let trx: CreateAccountInfo = try await ParseStrategyUtils.parse(
      at: "trx-create-bop-account.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.newWallet?.token.symbol, "BOP")
    XCTAssertEqual(trx.newWallet?.pubkey, "3qjHF2CHQbPEkuq3cTbS9iwfWfSsHsqmgyMj7M2ZuVSx")
  }
}
