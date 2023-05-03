// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class OrcaSwapStrategyTests: XCTestCase {
  lazy var apiClient = MockSolanaAPIClient()
  lazy var tokensRepository = MockTokensRepository()
  lazy var strategy = OrcaSwapParseStrategy(apiClient: apiClient, tokensRepository: tokensRepository)

  func testParsingSuccessfulTransaction() async throws {
    let trx: SwapInfo = try await ParseStrategyUtils.parse(
      at: "trx-swap-orca-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.sourceAmount, 0.001)
    XCTAssertEqual(trx.source?.pubkey, "BjUEdE292SLEq9mMeKtY3GXL6wirn7DqJPhrukCqAUua")
    XCTAssertEqual(trx.source?.token.symbol, "SRM")

    XCTAssertEqual(trx.destinationAmount, 0.00036488500000000001)
    XCTAssertEqual(trx.destination?.pubkey, "GYALxPybCjyv7N3DjpPQG3tH6M52UPLZ9eRyP5A7CXhW")
    XCTAssertEqual(trx.destination?.token.symbol, "SOL")
  }

  func testParsingTransitiveTransaction() async throws {
    let trx: SwapInfo = try await ParseStrategyUtils.parse(
      at: "trx-swap-orca-transitive-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.sourceAmount, 0.000999999)
    XCTAssertEqual(trx.source?.pubkey, "HVc47am8HPYgvkkCiFJzV6Q8qsJJKJUYT6o7ucd6ZYXY")
    XCTAssertEqual(trx.source?.token.symbol, "SOL")

    XCTAssertEqual(trx.destinationAmount, 0.088808)
    XCTAssertEqual(trx.destination?.pubkey, "ENYTT4Nw5YYKry9okt4Yx1dNJHzsUrH3s6HaeL1PtDb3")
    XCTAssertEqual(trx.destination?.token.symbol, "SLIM")
  }

  func testParsingFailedTransaction() async throws {
    let trx: SwapInfo = try await ParseStrategyUtils.parse(
      at: "trx-swap-orca-error.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.sourceAmount, 100.0)
    XCTAssertEqual(trx.source?.pubkey, "2xKofw1wK2CVMVUssGTv3G5pVrUALAR9r8J9zZnwtrUG")
    XCTAssertEqual(trx.source?.token.symbol, "KIN")

    XCTAssertNil(trx.destinationAmount)
    XCTAssertEqual(trx.destination?.pubkey, "G8PrkEwmVx3kt3rXBin5o1bdDC1cvz7oBnXbHksNg7R4")
    XCTAssertEqual(trx.destination?.token.symbol, "SOL")
  }

  func testBurningLiquidity() async throws {
    let trx: SwapInfo? = try await ParseStrategyUtils.parse(
      at: "trx-swap-orca-burn-liquidity.json",
      strategy: strategy,
      configuration: .init(accountView: "H1yu3R247X5jQN9bbDU8KB7RY4JSeEaCv45p5CMziefd", symbolView: nil, feePayers: [])
    )
    
    XCTAssertNil(trx)
  }

  func testProvideLiquidity() async throws {
    let trx: SwapInfo? = try await ParseStrategyUtils.parse(
      at: "trx-swap-orca-provide-liquidity.json",
      strategy: strategy,
      configuration: .init(accountView: "H1yu3R247X5jQN9bbDU8KB7RY4JSeEaCv45p5CMziefd", symbolView: nil, feePayers: [])
    )
    
    XCTAssertNil(trx)
  }
}
