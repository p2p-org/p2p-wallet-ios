// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import XCTest
@testable import JSBridge

class PromiseDispatchTableTests: XCTestCase {
    func testSuccessfulFlow() async throws {
        let dispatchTable = PromiseDispatchTable()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                let id = await dispatchTable.register(continuation: continuation)

                let nextID = await dispatchTable.promiseID
                XCTAssertEqual(nextID, 1, "Promise ID should be increased after register")

                let r = await dispatchTable.promiseDispatchTable.keys.count
                XCTAssertEqual(r, 1, "Dispatch table should register continuation")

                try await Task.sleep(nanoseconds: 5000)
                try await dispatchTable.resolve(for: id)
            }
        }

        let r = await dispatchTable.promiseDispatchTable.keys.count
        XCTAssertEqual(r, 0, "Dispatch table should unregister continuation after resolve")
    }

    func testFailedFlow() async throws {
        let dispatchTable = PromiseDispatchTable()

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                Task {
                    let id = await dispatchTable.register(continuation: continuation)

                    let nextID = await dispatchTable.promiseID
                    XCTAssertEqual(nextID, 1, "Promise ID should be increased after register")

                    let r = await dispatchTable.promiseDispatchTable.keys.count
                    XCTAssertEqual(r, 1, "Dispatch table should register continuation")

                    try await Task.sleep(nanoseconds: 5000)
                    try await dispatchTable.resolveWithError(for: id, error: JSBError.jsError("SomeError"))
                }
            }
        } catch let e {
            let r = await dispatchTable.promiseDispatchTable.keys.count
            XCTAssertEqual(r, 0, "Dispatch table should unregister continuation after resolve with error")
            XCTAssertTrue(e is JSBError, "Expected JSBError.jsError, but received: '\(e.localizedDescription)'")
            return
        }

        XCTExpectFailure("Expected error, but error isn't occur")
    }
}
