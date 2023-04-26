// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class SerumParseStrategyTests: XCTestCase {
  let endpoint = APIEndPoint.defaultEndpoints.first!

  lazy var tokensRepository = TokensRepository(endpoint: endpoint)
  lazy var strategy = SerumSwapParseStrategy(tokensRepository: tokensRepository)

  func skipTestParsingSerum1() async throws {
    let trx: SwapInfo = try await ParseStrategyUtils.parse(
      at: "trx-swap-serum-1.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "SOL")
    XCTAssertEqual(trx.source?.pubkey, "D7XYERWodEGaoN2X855T2qLvse28BSjfkvfCyW2EDBWy")
    XCTAssertEqual(trx.sourceAmount, 0.1)

    XCTAssertEqual(trx.destination?.token.symbol, "USDC")
    XCTAssertEqual(trx.destination?.pubkey, "375DTPnEBUjCnvQpGQtg5nRQudwa6oXWEYB15X6MmJs6")
    XCTAssertEqual(trx.destinationAmount?.toLamport(decimals: 6), 14_198_095)
  }

  func skipTestParsingSerum2() async throws {
    let trx: SwapInfo = try await ParseStrategyUtils.parse(
      at: "trx-swap-serum-2.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "BTC")
    XCTAssertEqual(trx.source?.pubkey, "FfH77kuL45qgqALsxtz6ktfSgbLSPfrB23AsoDnBxqUj")
    XCTAssertEqual(trx.sourceAmount, 0.001)

    XCTAssertEqual(trx.destination?.token.symbol, "soETH")
    XCTAssertEqual(trx.destination?.pubkey, "FT3A24vCezU25TzvDfPmDdHwpHDQdYZU4Z6Lt3Kf8WsT")
    XCTAssertEqual(
      trx.destinationAmount?.toLamport(decimals: trx.destination?.token.decimals ?? 0),
      13000
    )
  }

  func skipTestParsingSerum3() async throws {
    let trx: SwapInfo = try await ParseStrategyUtils.parse(
      at: "trx-swap-serum-3.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "USDC")
    XCTAssertEqual(trx.source?.pubkey, "375DTPnEBUjCnvQpGQtg5nRQudwa6oXWEYB15X6MmJs6")
    XCTAssertEqual(trx.sourceAmount, 5)

    XCTAssertEqual(trx.destination?.token.symbol, "SRM")
    XCTAssertEqual(trx.destination?.pubkey, "6Q49AE4NGeTXYDyyXx8gEVxJV28Vsn6bVJp4w3UqTByg")
    XCTAssertEqual(
      trx.destinationAmount?.toLamport(decimals: trx.destination?.token.decimals ?? 0),
      500_000
    )
  }

  func skipTestParsingSerum4() async throws {
    let trx: SwapInfo = try await ParseStrategyUtils.parse(
      at: "trx-swap-serum-4.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "USDT")
    XCTAssertEqual(trx.source?.pubkey, "GYYHwdXW7v8RaXv7zXvhQSJYKU9b9RMtRB2dufu9fnpR")
    XCTAssertEqual(trx.sourceAmount, 2)

    XCTAssertEqual(trx.destination?.token.symbol, "USDC")
    XCTAssertEqual(trx.destination?.pubkey, "8TnZDzWSzkSrRVxwGY6uPTaPSt2NDBvKD6uA5SZD3P87")
    XCTAssertEqual(
      trx.destinationAmount?.toLamport(decimals: trx.destination?.token.decimals ?? 0),
      1_993_604
    )
  }
}
