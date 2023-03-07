// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// A protocol for network request.
public protocol NetworkManager {
    func requestData(request: URLRequest) async throws -> Data
}

public struct URLSessionMock: NetworkManager {
    public init() {}

    public func requestData(request: URLRequest) async throws -> Data {
        debugPrint(request.allHTTPHeaderFields)
        if let body = request.httpBody {
            debugPrint(String(data: body, encoding: .utf8))
            debugPrint(try? JSONSerialization.jsonObject(with: body))
        }

        return Data()
    }
}

extension URLSession: NetworkManager {
    public func requestData(request: URLRequest) async throws -> Data {
        let (data, _): (Data, URLResponse)
        (data, _) = try await self.data(for: request)
        return data
    }

    func data(for urlRequest: URLRequest) async throws -> (Data, URLResponse) {
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
