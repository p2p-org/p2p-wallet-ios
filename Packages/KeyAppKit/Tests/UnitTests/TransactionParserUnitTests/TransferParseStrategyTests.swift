// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class TransferParseStrategyTests: XCTestCase {
  lazy var apiClient = MockSolanaAPIClient()
  lazy var tokensRepository = MockTokensRepository()
  lazy var strategy = TransferParseStrategy(apiClient: apiClient, tokensRepository: tokensRepository)

  func testTranferParsing() async throws {
    let trx: TransferInfo = try await ParseStrategyUtils.parse(
      at: "trx-transfer-sol-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "SOL")
    XCTAssertEqual(trx.source?.pubkey, "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm")
    XCTAssertEqual(trx.destination?.pubkey, "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")
    XCTAssertEqual(trx.authority, nil)
    XCTAssertEqual(trx.destinationAuthority, nil)
    XCTAssertEqual(trx.rawAmount, 0.01)
  }

  func testTransferSOLPaidByP2P() async throws {
    let trx: TransferInfo = try await ParseStrategyUtils.parse(
      at: "trx-transfer-sol-p2p-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "SOL")
    XCTAssertEqual(trx.source?.pubkey, "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm")
    XCTAssertEqual(trx.destination?.pubkey, "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")
    XCTAssertEqual(trx.authority, nil)
    XCTAssertEqual(trx.destinationAuthority, nil)
    XCTAssertEqual(trx.rawAmount, 0.00001)
  }

  func testTransferSPLToSOL() async throws {
    let trx: TransferInfo = try await ParseStrategyUtils.parse(
      at: "trx-transfer-spl-to-sol-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "soUSDT")
    XCTAssertEqual(trx.source?.pubkey, "22hXC9c4SGccwCkjtJwZ2VGRfhDYh9KSRCviD8bs4Xbg")
    XCTAssertEqual(trx.destination?.pubkey, "GCmbXJRc6mfnNNbnh5ja2TwWFzVzBp8MovsrTciw1HeS")
    XCTAssertEqual(trx.authority, "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm")
    XCTAssertEqual(trx.destinationAuthority, "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")
    XCTAssertEqual(trx.amount, 0.004325)
  }

  func testTransferSplToSpl() async throws {
    let trx: TransferInfo = try await ParseStrategyUtils.parse(
      at: "trx-transfer-spl-to-spl-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "SRM")
    XCTAssertEqual(trx.source?.pubkey, "BjUEdE292SLEq9mMeKtY3GXL6wirn7DqJPhrukCqAUua")
    XCTAssertEqual(trx.destination?.pubkey, "3YuhjsaohzpzEYAsonBQakYDj3VFWimhDn7bci8ERKTh")
    XCTAssertEqual(trx.authority, "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")
    XCTAssertEqual(trx.amount, 0.012111)
  }

  func testTransferTokenToNewAssociatedTokenAddress() async throws {
    let trx: TransferInfo = try await ParseStrategyUtils.parse(
      at: "trx-transfer-with-associated-account-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "MAPS")
    XCTAssertEqual(trx.source?.pubkey, "H1yu3R247X5jQN9bbDU8KB7RY4JSeEaCv45p5CMziefd")
    XCTAssertEqual(trx.amount, 0.001)
    XCTAssertEqual(trx.authority, "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm")
    XCTAssertEqual(trx.destinationAuthority, "4SSqj9qMm4GGt8LFonZKDRwE6oYZ9XdJ21bh37oiYHmC")
  }

  func testTransferTokenToNewAssociatedTokenAddressChecked() async throws {
    let trx: TransferInfo = try await ParseStrategyUtils.parse(
      at: "trx-transfer-no-associated-account-ok.json",
      strategy: strategy,
      configuration: .init(accountView: nil, symbolView: nil, feePayers: [])
    )!
    
    XCTAssertEqual(trx.source?.token.symbol, "MAPS")
    XCTAssertEqual(trx.source?.pubkey, "H1yu3R247X5jQN9bbDU8KB7RY4JSeEaCv45p5CMziefd")
    XCTAssertEqual(trx.amount, 0.001)
    XCTAssertEqual(trx.authority, "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm")
    XCTAssertEqual(trx.destinationAuthority, "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")
  }

  func testTransferSPLTokenParsedInNativeSOLWallet() async throws {
    let trx: TransferInfo = try await ParseStrategyUtils.parse(
      at: "trx-transfer-spl-native-wallet-ok.json",
      strategy: strategy,
      configuration: .init(accountView: "5ADqZHdZzL3xd2NiP8MrM4pCFj5ijC4oQWSBzvXx4fbY", symbolView: nil, feePayers: [])
    )!

    XCTAssertEqual(trx.source?.token.symbol, "RAY")
    XCTAssertEqual(trx.authority, "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")
    XCTAssertEqual(trx.source?.pubkey, "5ADqZHdZzL3xd2NiP8MrM4pCFj5ijC4oQWSBzvXx4fbY")
    XCTAssertEqual(trx.destination?.pubkey, "4ijqHixcbzhxQbfJWAoPkvBhokBDRGtXyqVcMN8ywj8W")
    XCTAssertEqual(trx.authority, "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")
    XCTAssertEqual(trx.transferType, .send)
  }
}
