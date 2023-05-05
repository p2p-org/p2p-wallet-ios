// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class TransactionParserImplTests: XCTestCase {
  lazy var apiClient = MockSolanaAPIClient()
  lazy var parseService: TransactionParserServiceImpl = TransactionParserServiceImpl.default(apiClient: apiClient)

  func testParsing() async throws {
    let rawTrx: TransactionInfo = ParseStrategyUtils.readTransaction(at: "trx-transfer-sol-ok.json")

    let trx = try await parseService.parse(
      rawTrx,
      config: .init(accountView: nil, symbolView: nil, feePayers: [])
    )

    XCTAssertEqual(trx.status, .confirmed)
    XCTAssertEqual(
      trx.signature,
      "5hJfaZoyjTrJcchXLFXRySgDMtGRiLsqvmrtpXcQjZq1Zc2d7Qj3LisaAtaFDtS9tDdv4aZ5n4fbtJNfVMCNV8Lj"
    )
    XCTAssertEqual(trx.slot, 72_410_024)
    XCTAssertNotNil(trx.fee)
    XCTAssertNotNil(trx.info)
  }

  func testParsingErrorTransaction() async throws {
    let rawTrx: TransactionInfo = ParseStrategyUtils.readTransaction(at: "trx-swap-orca-error.json")

    let trx = try await parseService.parse(
      rawTrx,
      config: .init(accountView: nil, symbolView: nil, feePayers: [])
    )

    XCTAssertEqual(trx.status, .error("Swap instruction exceeds desired slippage limit"))
    XCTAssertEqual(
      trx.signature,
      "376DxeSPgG1ynjpGFLLx5xFTTkVmQ54MmUcTuopKyEQXWQCu9PRzUZ2EijYi4YZq4eAPpRDdoQHzy59bfuNndLX4"
    )
    XCTAssertEqual(trx.slot, 83_929_593)
    XCTAssertNotNil(trx.fee)
    XCTAssertNotNil(trx.info)
  }
}
