// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// The class will be used for waiting js async functions by using continuation.
actor PromiseDispatchTable {
    typealias PromiseID = Int64

    /// Current unused id
    var promiseID: PromiseID = 0
    
    /// Promise table
    var promiseDispatchTable: [Int64: CheckedContinuation<Void, Swift.Error>] = .init()

    /// Register a new continuation and return id
    func register(continuation: CheckedContinuation<Void, Swift.Error>) -> Int64 {
        defer { promiseID = promiseID + 1 }
        promiseDispatchTable[promiseID] = continuation
        return promiseID
    }

    /// Resume continuation by id and free it.
    func resolve(for id: PromiseID) throws {
        guard let continuation = promiseDispatchTable[id] else {
            throw PromiseDispatchTableError.promiseIsResolved
        }
        
        continuation.resume(returning: ())
        promiseDispatchTable.removeValue(forKey: id)
    }

    /// Resume continuation with error by id and free it.
    func resolveWithError(for id: PromiseID, error: Error) throws {
        guard let continuation = promiseDispatchTable[id] else {
            throw PromiseDispatchTableError.promiseIsResolved
        }
        
        continuation.resume(throwing: error)
        promiseDispatchTable.removeValue(forKey: id)
    }
}

enum PromiseDispatchTableError: Error {
    case promiseIsResolved
}