//
//  JSBValueTests.swift
//  JSBridgeIntegrationTests
//
//  Created by Giang Long Tran on 11.07.2022.
//

import XCTest
@testable import JSBridge
import WebKit

class JSBValueTests: XCTestCase {
    @MainActor func testToString() async throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)
        
        // Ok case
        try await context.evaluate("a = \"abc\"")
        
        let value = JSBValue(in: context, name: "a")
        let stringResult = try await value.toString()
        XCTAssertEqual(stringResult, "abc")
        
        // Special cases
        try await context.evaluate("a = { b: 6 }")
        
        let value2 = JSBValue(in: context, name: "a")
        let stringResult2 = try await value2.toString()
        XCTAssertEqual(stringResult2, "[object Object]")
    }
    
    @MainActor func testToInt() async throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)
        
        // Ok case
        try await context.evaluate("a = 5")
        
        var value = JSBValue(in: context, name: "a")
        var stringResult = try await value.toInt()
        XCTAssertEqual(stringResult, 5)
        
        // Bad case
        try await context.evaluate("a = \"abc\"")
        
        value = JSBValue(in: context, name: "a")
        stringResult = try await value.toInt()
        XCTAssertNil(stringResult)
    }
    
    @MainActor func testValueForKey() async throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)
        
        // Normal case
        try await context.evaluate("a = {someProperty: 5}")
        
        let value = JSBValue(in: context, name: "a")
        let someProperty = try await value.valueForKey("someProperty")
        let stringResult = try await someProperty.toInt()
        XCTAssertEqual(stringResult, 5)
        
        // Nil context
        do {
            let value = JSBValue(name: "b")
            let _ = try await value.valueForKey("someProperty")
            XCTExpectFailure()
        } catch {}
    }
    
    
    @MainActor func testSetValueForKey() async throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)
        
        // Normal case
        try await context.evaluate("a = {someProperty: 5}")
        let anotherValue = try await JSBValue(number: 10, in: context)
        let value = JSBValue(in: context, name: "a")
        try await value.setValue(for: "b", value: anotherValue)
        
        let result = try await value.valueForKey("b").toInt()
        
        XCTAssertEqual(result, 10)
        
        // Nil context
        do {
            let value = JSBValue(name: "b")
            let _ = try await value.setValue(for: "someProperty", value: .init(string: "abc", in: context))
            XCTExpectFailure()
        } catch {}
    }
    
    @MainActor func testInvokeMethod() async throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)
        
        // Normal case
        try await context.evaluate("function someFunc(arg1) { console.log(arg1); }")
        
        do {
            let _ = try await context.this.invokeMethod("someFunc", withArguments: [5])
        } catch let e {
            print(e)
            XCTExpectFailure()
        }
        
        // Bade case
        // Normal case
        try await context.evaluate("function someFuncWithError(arg1) { throw 'Error' }")
        
        do {
            let _ = try await context.this.invokeMethod("someFuncWithError", withArguments: [5])
            XCTExpectFailure()
        } catch {}
    }
    
    @MainActor func testInvokeAsyncMethod() async throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)
        
        // Normal case
        try await context.evaluate("""
        function sleep(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        }
        
        async function someAsyncFunc(arg1) {
            await sleep(1000);
            return 10 * arg1;
        }
        
        async function someAsyncThrowingFunc(arg1) {
            await sleep(1000);
            throw 'MyError'
            return 10 * arg1;
        }
        """)
        
        do {
            let value = try await context.this.invokeAsyncMethod("someAsyncFunc", withArguments: [5])
            let result = try await value.toInt()
            XCTAssertEqual(result, 50)
        } catch {
            XCTExpectFailure()
        }
        
        do {
            let _ = try await context.this.invokeAsyncMethod("someAsyncThrowingFunc", withArguments: [5])
            XCTExpectFailure()
        } catch {}
        
        
        // Bade case
        try await context.evaluate("function someFuncWithError(arg1) { throw 'Error' }")
        
        do {
            let _ = try await context.this.invokeAsyncMethod("someAsyncFunc(", withArguments: [5])
            XCTExpectFailure()
        } catch {}
    }
    
}
