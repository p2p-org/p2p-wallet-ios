//
//  PricesParserTests.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 25/06/2021.
//

import XCTest
import RxBlocking
@testable import p2p_wallet

private struct Repository: TokensRepository {
    var supportedTokens: [SolanaSDK.Token] {
        try! SolanaSDK.TokensListParser()
            .parse(network: "mainnet-beta")
    }
}

class CryptoComparePricesFetcherTests: XCTestCase {
    var priceFetcher: CryptoComparePricesFetcher!
    private var repository: Repository!

    override func setUpWithError() throws {
        priceFetcher = CryptoComparePricesFetcher()
        repository = Repository()
    }

    override func tearDownWithError() throws {
        priceFetcher = nil
        repository = nil
    }

    func testFetchingPrices() throws {
        let coins = repository.supportedTokens.map {$0.symbol}
        let request = priceFetcher.getCurrentPrices(coins: coins, toFiat: "USD")
        
        let result = try request.toBlocking().first()
        
        XCTAssertNotEqual(0, result?.keys.count)
    }

}
