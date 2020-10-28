//
//  SolanaSwiftSDKTests.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 10/26/20.
//

import XCTest
import SolanaSwift
import RxBlocking
import RxSwift

class AccountTests: XCTestCase {
    var solanaSDK: SolanaSDK!
    let storage = InMemoryAccountStorage()

    override func setUpWithError() throws {
        if storage.account == nil {
            solanaSDK = SolanaSDK(accountStorage: storage)
            try solanaSDK.createAccount()
        }
    }

    override func tearDownWithError() throws {
        
    }
    
    func testGetBalance() throws {
        guard let account = storage.account?.publicKey.base58EncodedString else {
            throw SolanaSDK.Error.accountNotFound
        }
        let balance = try solanaSDK.getBalance(account: account).toBlocking().first()
        XCTAssertEqual(balance, 0)
    }
    
    func testGetAccountInfo() throws {
        guard let account = storage.account?.publicKey.base58EncodedString else {
            throw SolanaSDK.Error.accountNotFound
        }
        let accountInfo = try solanaSDK.getAccountInfo(account: account).toBlocking().first()
        XCTAssertNotNil(accountInfo)
    }
    
    func testRequestAirDrop() throws {
        guard let account = storage.account?.publicKey.base58EncodedString else {
            throw SolanaSDK.Error.accountNotFound
        }
        let response = try solanaSDK.requestAirdrop(account: account, lamports: 89588000).toBlocking().first()
        XCTAssertNotNil(response)
    }
}
