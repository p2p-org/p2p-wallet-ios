// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class DefaultFeeParseStrategyTests: XCTestCase {
  lazy var apiClient = MockSolanaAPIClient()
  lazy var tokensRepository = MockTokensRepository()
  lazy var strategy: DefaultFeeParseStrategy = .init(apiClient: apiClient)

  func testGetLamportPerSignature() async throws {
    let value = try await strategy.getLamportPerSignature()
    XCTAssertTrue(value > 0)

    let cachedValue = try await strategy.getLamportPerSignature()
    XCTAssertEqual(cachedValue, value)
  }

  func testGetRentException() async throws {
    let value = try await strategy.getRentException()
    XCTAssertTrue(value > 0)

    let cachedValue = try await strategy.getRentException()
    XCTAssertEqual(cachedValue, value)
  }

  func testTransfer() async throws {
    let rawTrx = ParseStrategyUtils.readTransaction(at: "trx-transfer-sol-ok.json")

    let fee = try await strategy.calculate(transactionInfo: rawTrx, feePayers: [])
    XCTAssertEqual(fee.transaction, 5000)
    XCTAssertEqual(fee.accountBalances, 0)
    XCTAssertEqual(fee.deposit, 0)
    XCTAssertNil(fee.others)
  }

  func testCreateAccount() async throws {
    let rawTrx = ParseStrategyUtils.readTransaction(at: "trx-create-account-ok.json")

    let fee = try await strategy.calculate(transactionInfo: rawTrx, feePayers: [])
    XCTAssertEqual(fee.transaction, 10000)
    XCTAssertEqual(fee.accountBalances, 2039280)
    XCTAssertEqual(fee.deposit, 0)
    XCTAssertNil(fee.others)
  }

  func testTransactionWithP2PFeePayer() async throws {
    let rawTrx = ParseStrategyUtils.readTransaction(at: "trx-transfer-sol-p2p-ok.json")

    let fee = try await strategy.calculate(
      transactionInfo: rawTrx,
      feePayers: ["FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT"]
    )
    XCTAssertEqual(fee.transaction, 0)
    XCTAssertEqual(fee.accountBalances, 0)
    XCTAssertEqual(fee.deposit, 0)
    XCTAssertNil(fee.others)
  }
}
