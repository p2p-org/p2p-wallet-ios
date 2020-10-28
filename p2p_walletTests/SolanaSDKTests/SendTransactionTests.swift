//
//  SendTransactionTests.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 10/28/20.
//

import XCTest
import SolanaSwift

class SendTransactionTests: XCTestCase {
    var solanaSDK: SolanaSDK!
    let storage = InMemoryAccountStorage()

    override func setUpWithError() throws {
        if storage.account == nil {
            solanaSDK = SolanaSDK(accountStorage: storage)
            try solanaSDK.createAccount()
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSendingTransaction() throws {
        
    }
}
