// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class P2POrcaSwapWrapperStrategyTests: XCTestCase {
  lazy var apiClient = MockSolanaAPIClient()
  lazy var tokensRepository = MockTokensRepository()
  lazy var strategy = P2POrcaSwapWrapperParseStrategy(apiClient: apiClient, tokensRepository: tokensRepository)

  func testParsingTransitiveSwap() async throws {
    
    
    let trx: SwapInfo? = try await ParseStrategyUtils.parse(
      at: "trx-p2p-swap-orca-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )
    
    guard let trx = trx else {
      XCTFail("The transaction should be parsed")
      return
    }

    XCTAssertEqual(trx.sourceAmount!, 0.0051, accuracy: 5)
    XCTAssertEqual(trx.source?.pubkey, "BChCFxutjFZbLzo7RFdJFFLxK61wQZGPUzQUhaRUbyZq")
    XCTAssertEqual(trx.source?.token.address, "7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs")

    XCTAssertEqual(trx.destinationAmount!, 0.23747241, accuracy: 5)
    XCTAssertEqual(trx.destination?.pubkey, "9zRnk58ydEKxQ4BKyETG8uQQecppcxMvQaJWLkjocvPm")
    XCTAssertEqual(trx.destination?.token.address, "So11111111111111111111111111111111111111112")
  }

  
}
