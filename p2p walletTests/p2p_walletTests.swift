//
//  p2p_walletTests.swift
//  p2p walletTests
//
//  Created by Chung Tran on 10/22/20.
//

import XCTest
import JavaScriptCore

class p2p_walletTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let jsPath = Bundle.main.path(forResource: "solana", ofType: "js")!
        let string = try String(contentsOfFile: jsPath, encoding: String.Encoding.utf8)
        let context = JSContext.plus
        context?.exceptionHandler = { context, exception in
            print(exception!.toString())
        }
        context?.evaluateScript(string)
//        let value = context?.evaluateScript("this")
//        print(value?.toDictionary())
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
