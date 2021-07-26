//
//  PricesParserTests.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 25/06/2021.
//

import XCTest
import RxBlocking
import RxSwift
@testable import p2p_wallet

private struct Repository: TokensRepository {
    func getTokensList() -> Single<[SolanaSDK.Token]> {
        SolanaSDK.TokensListParser()
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
        let coins = try repository.getTokensList().map {$0.excludingSpecialTokens().map {$0.symbol}}.toBlocking().first()!
        let request = priceFetcher.getCurrentPrices(coins: coins, toFiat: "USD")
        
        let result = try request.toBlocking().first()
        
        XCTAssertNotEqual(0, result?.keys.count)
    }

}
