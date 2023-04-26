import WebKit
import XCTest
@testable import JSBridge

class JSBValueTests: XCTestCase {
    func testBase() async throws {
        let v = JSBValue(name: "customName")
        XCTAssertEqual(v.name, "customName")
    }

    func testParseArgs() throws {
        let v = JSBValue(name: "someValue")

        var result: String

        result = try v.parseArgs(["abc"])
        XCTAssertEqual(result, "\"abc\"", "String should be parse correctly")

        result = try v.parseArgs(["ab\"c"])
        XCTAssertEqual(result, "\"ab\\\"c\"", "String with double quotation mark should be parse correctly")

        result = try v.parseArgs([1])
        XCTAssertEqual(result, "1")

        result = try v.parseArgs([Int.max])
        XCTAssertEqual(result, "\(Int.max)")

        result = try v.parseArgs([Int.min])
        XCTAssertEqual(result, "\(Int.min)")

        XCTAssertThrowsError(try v.parseArgs([0.000000000000000000000001]))
        XCTAssertThrowsError(try v.parseArgs([Float(0.00001)]))

        result = try v.parseArgs([[1, "abc", [1, 2, 3]]])
        XCTAssertEqual(result, "[1,\"abc\",[1,2,3]]")

        result = try v.parseArgs([["a": 1, "b": "b"]])
        XCTAssertEqual(result, "{\"a\":1,\"b\":\"b\"}")

        let tv = JSBValue(name: "someVal2")
        result = try v.parseArgs([tv])
        XCTAssertEqual(result, "\(tv.name)")

        struct S: CustomStringConvertible {
            var description: String = ""
            let a: String
            
        }
        
        XCTAssertThrowsError(try v.parseArgs([S(a: "abc")]))
    }
}
