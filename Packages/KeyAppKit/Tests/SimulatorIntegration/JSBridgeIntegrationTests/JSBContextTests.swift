//
//  JSBridgeIntegrationTests.swift
//  JSBridgeIntegrationTests
//
//  Created by Giang Long Tran on 08.07.2022.
//

import XCTest
@testable import JSBridge
import WebKit

class JSBContextTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()
    }

    @MainActor func testInit1() async throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)

        let msg = "Hello world"
        let str = try await JSBValue(string: msg, in: context)
        try await context.this.setValue(for: "test", value: str)

        let test = try await context.this.valueForKey("test").toString()
        XCTAssertEqual(test, msg)
    }
    
    @MainActor func testInit2() async throws {
        let context = JSBContext()

        let msg = "Hello world"
        let str = try await JSBValue(string: msg, in: context)
        try await context.this.setValue(for: "test", value: str)

        let test = try await context.this.valueForKey("test").toString()
        XCTAssertEqual(test, msg)
    }
    
    @MainActor func testEvaluateVoid() async throws {
        let context = JSBContext()

        do {
            try await context.evaluate("abc = 5")
        } catch {
            XCTExpectFailure()
        }
        
        do {
            try await context.evaluate("abc = 5 = 6")
            XCTExpectFailure()
        } catch {}
    }
    
    @MainActor func testEvaluateWithReturn() async throws {
        let context = JSBContext()

        do {
            let v: Int? = try await context.evaluate("5")
            XCTAssertEqual(v, 5)
        } catch {
            XCTExpectFailure()
        }
        
        do {
            let _: Int? = try await context.evaluate("5 = 6")
            XCTExpectFailure()
        } catch {}
    }
    
}
