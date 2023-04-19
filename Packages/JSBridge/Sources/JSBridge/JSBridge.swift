// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public protocol JSBridge {
    /// Get js value by key. [object.property]
    ///
    /// - Parameter key: object key
    /// - Returns: reference to value
    func valueForKey(_ key: String) async throws -> JSBValue

    /// Set js value with key. [object.property = jsValue]
    ///
    /// - Parameters:
    ///   - key: Object key
    ///   - value: reference to value
    /// - Throws:
    func setValue(for key: String, value: JSBValue) async throws

    /// Invoke method of value. [object.method(args)]
    ///
    /// - Parameters:
    ///   - method: method name
    ///   - args: arguments that method accepts
    /// - Returns: Reference to value
    func invokeMethod(_ method: String, withArguments args: [CustomStringConvertible]) async throws -> JSBValue

    /// Invoke async method. [await object.method()].
    ///
    /// - Parameters:
    ///   - method: method name
    ///   - args: arguments that method accepts
    /// - Returns: Reference to value
    func invokeAsyncMethod(
        _ method: String,
        withArguments args: [CustomStringConvertible]
    ) async throws -> JSBValue

    /// Invoke initialize. [new object]
    func invokeNew(withArguments args: [CustomStringConvertible]) async throws -> JSBValue
}
