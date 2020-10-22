//
//  p2p_walletTests.swift
//  p2p walletTests
//
//  Created by Chung Tran on 10/22/20.
//

import XCTest

class AccountTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateAccount() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let account = try Account(phrase: "ordinary cover language pole achieve pause focus core sing lady zoo fix".components(separatedBy: " "))
        print(account.publicKey)
        XCTAssertEqual(account.publicKey, "C7PLa6JhGaqFwuhtMXxtjYiV1CkzVrTvqusQ12D1cY4F")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
