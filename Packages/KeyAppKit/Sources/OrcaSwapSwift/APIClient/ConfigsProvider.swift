//
//  File.swift
//  
//
//  Created by Chung Tran on 09/05/2022.
//

import Foundation

public protocol OrcaSwapConfigsProvider {
    func getData(reload: Bool) async throws -> Data
}

extension OrcaSwapConfigsProvider {
    func getConfigs() async throws -> Data {
        try await getData(reload: false)
    }
}

public class NetworkConfigsProvider: OrcaSwapConfigsProvider {
    public let network: String
    public var cache: Data?
    private let urlString = "https://orca.key.app/info"
    private let locker = NSLock()
    
    public init(network: String) {
        self.network = network
    }
    
    public func getData(reload: Bool = false) async throws -> Data {
        if !reload, let cache = cache {
            return cache
        }
        // hack: network
        var network = network
        if network == "mainnet-beta" {network = "mainnet"}
        
        // prepare url
        let url = URL(string: urlString)!
        
        // get
        let (data, _): (Data, URLResponse)
        if #available(iOS 15.0, macOS 12.0, *) {
            (data, _) = try await URLSession.shared.data(for: .init(url: url))
        } else {
            (data, _) = try await URLSession.shared.data(from: url)
        }
        
        locker.lock()
        cache = data
        locker.unlock()
        
        return data
    }
}

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
