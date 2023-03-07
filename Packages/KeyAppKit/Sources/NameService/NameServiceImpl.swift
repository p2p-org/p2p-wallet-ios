// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppKitLogger
import KeyAppKitCore
import SolanaSwift
import TweetNacl

public class NameServiceImpl: NameService {
    private let endpoint: String
    private let cache: NameServiceCacheType

    public init(endpoint: String, cache: NameServiceCacheType) {
        self.endpoint = endpoint
        self.cache = cache
    }

    public func getName(_ owner: String) async throws -> String? {
        if let result = cache.getName(for: owner) {
            return result.name
        }

        let name = try await lookupName(owner: owner).last?.name
        cache.save(name, for: owner)
        return name
    }

    public func getOwners(_ name: String) async throws -> [NameRecord] {
        do {
            let result: [NameRecord] = try await resolveName(name)
            for record in result {
                if let name = record.name {
                    cache.save(name, for: record.owner)
                }
            }
            return result
        } catch let error as NameServiceError {
            return []
        }
    }

    public func getOwnerAddress(_ name: String) async throws -> String? {
        do {
            return try await getName(name)?.owner
        } catch let error as NameServiceError {
            return nil
        }
    }

    // TODO: Tech debt, don't delete.
    // This method will be used after release for users not authorized with web3auth. For now it is not changed to JSONRPC
    public func post(name: String, params: PostParams) async throws -> PostResponse {
        let urlString = "\(endpoint)/\(name)"
        let url = URL(string: urlString)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(params)
        try Task.checkCancellation()
        let (data, response) = try await URLSession.shared.data(from: urlRequest)
        try Task.checkCancellation()
        let stringResponse = String(data: data, encoding: .utf8)
        if let stringResponse = stringResponse, stringResponse.contains("insufficient funds for instruction") {
            throw UndefinedNameServiceError.unknown
        }
        return try JSONDecoder().decode(PostResponse.self, from: data)
    }

    public func create(name: String, publicKey: String, privateKey: Data) async throws -> CreateNameTransaction {
        let timestamp = Date()
        var serializedData = Data()
        let serialized = try CreateNameRequestMessage(
            owner: publicKey,
            timestamp: Int64(timestamp.timeIntervalSince1970)
        ).serialize(to: &serializedData)

        let signature = try NaclSign.signDetached(message: serializedData, secretKey: privateKey)
        let signatureBase58 = Base58.encode(signature)
        let credentials = CreateNameRequestParams(
            name: name,
            owner: publicKey,
            credentials: .init(timestamp: timestamp, signature: signatureBase58)
        )

        let rpcRequest = JSONRPCRequest(
            id: UUID().uuidString,
            method: NameServiceMethod.createName.rawValue,
            params: credentials
        )
        let urlRequest = try createURLRequest(with: rpcRequest)
        let response: KeyAppKitCore.JSONRPCResponse<CreateNameTransaction, ErrorData> = try await request(request: urlRequest)
        if let error = response.error {
            throw NameServiceError(rawValue: error.code) ?? UndefinedNameServiceError(code: error.code)
        }
        if let result = response.result {
            return result
        }
        throw UndefinedNameServiceError.unknown
    }

    private func getName(_ name: String) async throws -> NameRecord? {
        let rpcRequest = KeyAppKitCore.JSONRPCRequest(
            id: UUID().uuidString,
            method: NameServiceMethod.getName.rawValue,
            params: GetNameRequestParams(name: name)
        )
        let urlRequest = try createURLRequest(with: rpcRequest)
        let response: KeyAppKitCore.JSONRPCResponse<NameRecord, ErrorData> = try await request(request: urlRequest)
        if let error = response.error, error.code == GetNameError.nameNotFound.rawValue {
            return nil
        } else if let error = response.error {
            throw NameServiceError(rawValue: error.code) ?? UndefinedNameServiceError(code: error.code)
        }
        return response.result
    }

    private func resolveName(_ name: String) async throws -> [NameRecord] {
        let rpcRequest = KeyAppKitCore.JSONRPCRequest(
            id: UUID().uuidString,
            method: NameServiceMethod.resolveName.rawValue,
            params: GetNameRequestParams(name: name)
        )
        let urlRequest = try createURLRequest(with: rpcRequest)
        let response: KeyAppKitCore.JSONRPCResponse<[NameRecord], ErrorData> = try await request(request: urlRequest)
        if let error = response.error {
            throw NameServiceError(rawValue: error.code) ?? UndefinedNameServiceError(code: error.code)
        }
        return response.result ?? []
    }

    private func lookupName(owner: String) async throws -> [NameInfo] {
        let rpcRequest = KeyAppKitCore.JSONRPCRequest(
            id: UUID().uuidString,
            method: NameServiceMethod.lookupName.rawValue,
            params: LookupNameRequestParams(owner: owner)
        )
        let urlRequest = try createURLRequest(with: rpcRequest)
        let response: KeyAppKitCore.JSONRPCResponse<[NameInfo], ErrorData> = try await request(request: urlRequest)
        if let error = response.error {
            throw NameServiceError(rawValue: error.code) ?? UndefinedNameServiceError(code: error.code)
        }
        return response.result ?? []
    }

    private func createURLRequest<T: Encodable>(with body: JSONRPCRequest<T>) throws -> URLRequest {
        guard let url = URL(string: endpoint) else { throw UndefinedNameServiceError.unknown }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(body)
        return urlRequest
    }

    private func request<T: Decodable>(request: URLRequest) async throws -> T {
        try Task.checkCancellation()
        let (data, response) = try await URLSession.shared.data(from: request)
        guard let response = response as? HTTPURLResponse else {
            logError(event: "Invalid response code")
            throw UndefinedNameServiceError.unknown
        }

        try Task.checkCancellation()
        switch response.statusCode {
        case 200 ... 299:
            return try JSONDecoder().decode(T.self, from: data)
        default:
            logError(event: "response code: \(response.statusCode)", message: String(data: data, encoding: .utf8))
            throw UndefinedNameServiceError(code: response.statusCode)
        }
    }

    private func logError(event: String, message: String? = nil) {
        KeyAppKitLogger.Logger.log(event: "NameService: \(event)", message: message, logLevel: .error)
    }
}

private struct ErrorData: Codable { }
