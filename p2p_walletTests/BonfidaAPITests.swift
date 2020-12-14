//
//  BonfidaAPITests.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 11/12/2020.
//

import XCTest
import RxBlocking
@testable import p2p_wallet

class BonfidaAPITests: XCTestCase {
    func testGetHistoricalPrices() throws {
        let records = try PricesManager.shared.fetchHistoricalPrice(for: "BTC", period: .day).toBlocking().first()
        XCTAssertTrue(records?.count ?? 0 > 0)
    }
}
