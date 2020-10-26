//
//  SolanaSwiftSDKTests.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 10/26/20.
//

import XCTest
import SolanaSwift
import RxBlocking

class SolanaSwiftSDKTests: XCTestCase {
    class InMemoryStorage: SolanaSDKAccountStorage {
        private var _account: SolanaSDK.Account?
        func save(_ account: SolanaSDK.Account) throws {
            _account = account
        }
        var account: SolanaSDK.Account? {
            _account
        }
    }
    
    var solanaSDK: SolanaSDK!
    var storage = InMemoryStorage()

    override func setUpWithError() throws {
        if storage.account == nil {
            solanaSDK = SolanaSDK(accountStorage: storage)
            try solanaSDK.createAccount()
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetAccountInfo() throws {
        let accountInfo = try solanaSDK.getAccountInfo().toBlocking().first()
        XCTAssertNotNil(accountInfo)
    }

    func testGetBalance() throws {
        let balance = try solanaSDK.getBalance().toBlocking().first()
        XCTAssertEqual(balance?.value, 0)
    }
    
    func testRequestAirDrop() throws {
        let response = try solanaSDK.requestAirdrop().toBlocking().first()
        XCTAssertNotNil(response)
    }
}
