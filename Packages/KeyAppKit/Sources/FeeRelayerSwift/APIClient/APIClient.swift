// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// Default implementation of ``FeeRelayerAPIClient``
public class APIClient: FeeRelayerAPIClient {
    
    // MARK: - Properties
    
    /// Current FeeRelayer's version
    public let version: Int
    
    /// Base url of fee relayer server
    private let baseUrlString: String
    
    /// HTTPClient to handle requests
    private var httpClient: HTTPClient

    // MARK: - Initializers
    
    /// ``APIClient`` initializer
    /// - Parameters:
    ///   - httpClient: httpClient that handles requests
    ///   - baseUrlString: base url of fee relayer server
    ///   - version: current version of FeeRelayer
    public init(httpClient: HTTPClient = FeeRelayerHTTPClient(), baseUrlString: String, version: Int) {
        self.version = version
        self.httpClient = httpClient
        self.baseUrlString = baseUrlString
    }

    // MARK: - Methods

    /// Get fee payer account's public key
    /// - Returns: Public key as String
    public func getFeePayerPubkey() async throws -> String {
        var urlString = baseUrlString
        if version > 1 {
            urlString += "/v\(version)"
        }
        urlString += "/fee_payer/pubkey"
        guard let url = URL(string: urlString) else { throw APIClientError.invalidURL }
        let request = URLRequest(url: url)
        var res: String?
        do {
            res = try await httpClient.sendRequest(request: request, decoder: JSONDecoder())
        } catch let HTTPClientError.cantDecode(data) {
            res = String(data: data, encoding: .utf8)
            Logger.log(event: "FeeRelayerSwift getFeePayerPubkey", message: res, logLevel: .debug)
        }
        guard let res = res else { throw APIClientError.unknown }
        return res
    }
    
    /// Get free fee limits for current user
    /// - Parameter authority: user's authority
    /// - Returns: current user's usage limit
    public func getFreeFeeLimits(for authority: String) async throws -> FeeLimitForAuthorityResponse {
        var url = baseUrlString
        if version > 1 {
            url += "/v\(version)"
        }
        url += "/free_fee_limits/\(authority)"
        guard let url = URL(string: url) else { throw APIClientError.unknown }

        var urlRequest: URLRequest
        urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        Logger.log(event: "FeeRelayerSwift requestFreeFeeLimits", message: urlRequest.cURL(), logLevel: .debug)

        do {
            return try await httpClient.sendRequest(request: urlRequest, decoder: JSONDecoder()) as FeeLimitForAuthorityResponse
        } catch let HTTPClientError.unexpectedStatusCode(_, data) {
            Logger.log(event: "FeeRelayerSwift: requestFreeFeeLimits", message: String(data: data, encoding: .utf8), logLevel: .error)
            let decodedError = try JSONDecoder().decode(FeeRelayerError.self, from: data)
            throw decodedError
        }
    }
    
    /// Get free fee limits for current user
    /// - Parameter authority: user's authority
    /// - Returns: current user's usage limit
    @available(*, deprecated, renamed: "getFreeFeeLimits")
    public func requestFreeFeeLimits(for authority: String) async throws -> FeeLimitForAuthorityResponse {
        try await getFreeFeeLimits(for: authority)
    }
    
    /// Get fee token data
    public func feeTokenData(mint: String) async throws -> FeeTokenData {
        var url = baseUrlString
        if version > 1 {
            url += "/v\(version)"
        }
        url += "/fee_token_data/\(mint)"
        guard let url = URL(string: url) else { throw APIClientError.unknown }

        var urlRequest: URLRequest
        urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        Logger.log(event: "FeeRelayerSwift getFeeTokenData", message: urlRequest.cURL(), logLevel: .debug)

        do {
            return try await httpClient.sendRequest(request: urlRequest, decoder: JSONDecoder())
        } catch let HTTPClientError.unexpectedStatusCode(_, data) {
            Logger.log(event: "FeeRelayerSwift: getFeeTokenData", message: String(data: data, encoding: .utf8), logLevel: .error)
            let decodedError = try JSONDecoder().decode(FeeRelayerError.self, from: data)
            throw decodedError
        }
    }

    /// Send transaction to fee relayer server to process
    /// - Parameter requestType: FeeRelayer's Request Type
    /// - Returns: signature, can be confirmed or signature of fee payer account that can be added to process later by client
    public func sendTransaction(_ requestType: RequestType) async throws -> String {
        do {
            // Custom Response for sign_relay_transaction
            if requestType.path == "/sign_relay_transaction" {
                // Custom Response type
                struct Response: Decodable {
                    let signature: String
                    let transaction: String
                }
                
                let response: Response = try await httpClient.sendRequest(request: urlRequest(requestType), decoder: JSONDecoder())
                return response.signature
            }
            
            // Other response
            let response: String = try await httpClient.sendRequest(request: urlRequest(requestType), decoder: JSONDecoder())
            return response
        } catch let HTTPClientError.cantDecode(data) {
            guard let ret = String(data: data, encoding: .utf8) else { throw APIClientError.unknown }
            
            let signature = ret.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "\"", with: "")
            Logger.log(
                event: "FeeRelayerSwift sendTransaction",
                message: "Transaction has been successfully sent with signature: \(signature)",
                logLevel: .debug
            )
            return signature
        }
    }
    
    // MARK: - Helpers
    
    /// Form request
    /// - Parameter requestType: FeeRelayer's ``RequestType``
    /// - Returns: urlRequest
    private func urlRequest(_ requestType: RequestType) throws -> URLRequest {
        var url = baseUrlString
        if version > 1 {
            url += "/v\(version)"
        }
        url += requestType.path
        var urlRequest = URLRequest(url: URL(string: url)!)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try requestType.getParams()

        Logger.log(
            event: "FeeRelayerSwift urlRequest",
            message: urlRequest.cURL(),
            logLevel: .debug
        )
        return urlRequest
    }
}

// MARK: - Private extension

private extension URLRequest {
    /// Private extension for printing request
    func cURL(pretty: Bool = false) -> String {
        let newLine = pretty ? "\\\n" : ""
        let method = (pretty ? "--request " : "-X ") + "\(httpMethod ?? "GET") \(newLine)"
        let url: String = (pretty ? "--url " : "") + "\'\(self.url?.absoluteString ?? "")\' \(newLine)"

        var cURL = "curl "
        var header = ""
        var data = ""

        if let httpHeaders = allHTTPHeaderFields, httpHeaders.keys.count > 0 {
            for (key, value) in httpHeaders {
                header += (pretty ? "--header " : "-H ") + "\'\(key): \(value)\' \(newLine)"
            }
        }

        if let bodyData = httpBody, let bodyString = String(data: bodyData, encoding: .utf8), !bodyString.isEmpty {
            data = "--data '\(bodyString)'"
        }

        cURL += method + url + header + data

        return cURL
    }
}
