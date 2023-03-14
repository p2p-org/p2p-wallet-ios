// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// A generic data structure for json rpc
public struct JSONRPCResponse<T: Codable, U: Codable>: Codable {
    public let id: String
    public let jsonrpc: String
    public let result: T?
    public let error: JSONRPCError<U>?

    public init(id: String, jsonrpc: String, result: T?, error: JSONRPCError<U>?) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.result = result
        self.error = error
    }
}

public struct JSONRPCError<U: Codable>: Codable, LocalizedError {
    public let code: Int
    public let message: String
    public let data: U?

    public init(code: Int, message: String, data: U?) {
        self.code = code
        self.message = message
        self.data = data
    }

    public var errorDescription: String? {
        return "Code \(code). Reason: \(message)"
    }
}

public struct JSONRPCRequest<T: Codable>: Codable {
    public let id: String
    public let jsonrpc: String
    public let method: String
    public let params: T

    public init(id: String, jsonrpc: String = "2.0", method: String, params: T) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = params
    }
}
