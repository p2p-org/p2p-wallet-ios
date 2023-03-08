//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Cache
import Foundation
import Web3

/// The repository for fetching token metadata and cache for later usage.
public final class EthereumTokensRepository {
    /// Provider
    internal let web3: Web3

    /// In memory cache
    internal let cache: Cache<EthereumAddress, EthereumToken> = .init()

    public init(web3: Web3) {
        self.web3 = web3
    }

    /// Resolve ERC-20 token by address.
    public func resolve(address: String) async throws -> EthereumToken {
        let ethereumAddress = try EthereumAddress(hex: address, eip55: false)

        if let value = await cache.value(forKey: ethereumAddress) {
            return value
        }

        let metadata: EthereumTokenMetadata = try await withCheckedThrowingContinuation { continuation in
            web3.eth.getTokenMetadata(address: ethereumAddress) { response in
                switch response.status {
                case let .success(metadata):
                    continuation.resume(returning: metadata)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }

        let token = EthereumToken(address: ethereumAddress, metadata: metadata)
        await cache.insert(token, forKey: ethereumAddress)

        return token
    }
}

extension EthereumTokensRepository {
    enum Error: Swift.Error {}
}
