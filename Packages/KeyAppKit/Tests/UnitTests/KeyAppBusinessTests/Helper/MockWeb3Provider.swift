//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Foundation
import Web3

class MockWeb3Provider: Web3Provider {
    var stubs: [String: Data] = [:]

    func addStub(method: String, data: Data) {
        stubs[method] = data
    }

    func addStub<Result: Encodable & Decodable>(method: String, result: Result) throws {
        let response: RPCMockResponse<Result> = .init(id: 1, jsonrpc: "2.0", result: result, error: nil)
        stubs[method] = try JSONEncoder().encode(response)
    }

    func removeStub(method: String) {
        stubs[method] = nil
    }

    func send<Params, Result>(request: RPCRequest<Params>, response: @escaping (Web3Response<Result>) -> Void) {
        if let stubbedData = stubs[request.method] {
            do {
                let rpcResponse = try JSONDecoder().decode(RPCResponse<Result>.self, from: stubbedData)
                let res = Web3Response<Result>(rpcResponse: rpcResponse)
                response(res)
            } catch {
                let err = Web3Response<Result>(error: .decodingError(error))
                response(err)
            }
        } else {
            let err = Web3Response<Result>(error: .serverError(nil))
            response(err)
        }
    }
}

private struct RPCMockResponse<Result: Codable>: Codable {
    /// The rpc id
    public let id: Int

    /// The jsonrpc version. Typically 2.0
    public let jsonrpc: String

    /// The result
    public let result: Result?

    /// The error
    public let error: Error?

    public struct Error: Swift.Error, Codable {
        /// The error code
        public let code: Int

        /// The error message
        public let message: String

        /// Description
        public var localizedDescription: String {
            return "RPC Error (\(code)) \(message)"
        }
    }
}
