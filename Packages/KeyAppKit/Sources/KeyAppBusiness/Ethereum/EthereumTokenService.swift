//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Cache
import Foundation
import KeyAppKitCore
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

        let metadata: EthereumTokenMetadata = try await web3.eth.getTokenMetadata(address: ethereumAddress)

        let token = EthereumToken(address: ethereumAddress, metadata: metadata)
        await cache.insert(token, forKey: ethereumAddress)

        return token
    }
}

extension EthereumTokensRepository {
    enum Error: Swift.Error {}
}

extension EthereumToken {
    /// Erc-20 Token
    init(address: EthereumAddress, metadata: EthereumTokenMetadata) {
        self.init(
            name: metadata.name ?? "",
            symbol: metadata.symbol ?? "",
            decimals: metadata.decimals ?? 1,
            logo: metadata.logo,
            contractType: .erc20(contract: address)
        )
    }
}
