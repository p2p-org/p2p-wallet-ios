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
        XCTAssertEqual(records?.count, 24)
        let records2 = try PricesManager.shared.fetchHistoricalPrice(for: "BTC", period: .week).toBlocking().first()
        XCTAssertEqual(records2?.count, 7)
        let records3 = try PricesManager.shared.fetchHistoricalPrice(for: "BTC", period: .month).toBlocking().first()
        XCTAssertEqual(records3?.count, 30)
//        let records4 = try PricesManager.shared.fetchHistoricalPrice(for: "BTC", period: .year).toBlocking().first()
//        XCTAssertEqual(records4?.count, 12)
    }
}
