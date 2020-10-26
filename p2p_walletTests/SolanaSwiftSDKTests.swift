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

    override func setUpWithError() throws {
        solanaSDK = SolanaSDK(accountStorage: InMemoryStorage())
        try solanaSDK.createAccount()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetBalance() throws {
        let balance = try solanaSDK.getBalance().toBlocking().first()
        XCTAssertEqual(balance?.value, 0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
