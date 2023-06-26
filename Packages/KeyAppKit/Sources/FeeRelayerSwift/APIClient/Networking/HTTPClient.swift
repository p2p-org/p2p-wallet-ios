// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum HTTPClientError: Error {
    case noResponse
    case cantDecode(responseData: Data)
    case unauthorized
    case unexpectedStatusCode(code: Int, response: Data)
    case unknown(error: Error)
}

public protocol NetworkManager {
    func requestData(request: URLRequest) async throws -> (Data, URLResponse)
}

public protocol HTTPClient {
    var networkManager: NetworkManager { get set }
    func sendRequest<T: Decodable>(request: URLRequest, decoder: JSONDecoder) async throws -> T
}

public final class FeeRelayerHTTPClient: HTTPClient {
    public var networkManager: NetworkManager
    public init(networkManager: NetworkManager = URLSession.shared) {
        self.networkManager = networkManager
    }
    
    public func sendRequest<T: Decodable>(request: URLRequest, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
//        do {
            let (data, response) = try await networkManager.requestData(request: request)
            guard let response = response as? HTTPURLResponse else { throw HTTPClientError.noResponse }
            switch response.statusCode {
            case 200 ... 299:
                guard let decodedResponse = try? decoder.decode(T.self, from: data) else {
                    throw HTTPClientError.cantDecode(responseData: data)
                }
                return decodedResponse
            case 401:
                throw HTTPClientError.unauthorized
            default:
                if let log = String(data: data, encoding: .utf8) {
                    #if DEBUG
                    Logger.log(event: "error", message: log, logLevel: .error)
                    print(log)
                    #endif
                    // FIXME: - temporarily fix by converting HTTPClientError to SolanaError
                    if let fixedData = log.data(using: .utf8),
                       let responseError = try? JSONDecoder().decode(CustomError.self, from: fixedData)
                        .ClientError
                        .first?
                        .RpcResponseError
                    {
                        throw SolanaSwift.APIClientError.responseError(
                            .init(
                                code: responseError.code,
                                message: responseError.message,
                                data: .init(logs: responseError.data?.RpcSimulateTransactionResult?.logs)
                            )
                        )
                    }
                }
                
                throw HTTPClientError.unexpectedStatusCode(code: response.statusCode, response: data)
            }
//        } catch let error {
//            throw error
//        }
    }
}

// TODO: Move to a separate alonside HTTPClient SPM
@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
extension URLSession {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
    
    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: urlRequest) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }

}

@available(iOS 15, *)
extension URLSession: NetworkManager {
    public func requestData(request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(from: request)
    }
}

private struct CustomError: Decodable {
    let ClientError: [_ClientError]
    
    struct _ClientError: Decodable {
        let RpcResponseError: _RpcResponseError
        
        struct _RpcResponseError: Decodable {
            let code: Int?
            let message: String?
            let data: _RpcResponseErrorData?
            
            struct _RpcResponseErrorData: Decodable {
                let RpcSimulateTransactionResult: _RpcSimulateTransactionResult?
                
                struct _RpcSimulateTransactionResult: Decodable {
                    let logs: [String]?
                }
            }
        }
    }
}
