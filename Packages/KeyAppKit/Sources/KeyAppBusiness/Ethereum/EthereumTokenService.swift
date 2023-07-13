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
    let provider: KeyAppTokenProvider

    /// In memory cache to quickly return token. Token metadata doesn't change frequently.
    let database: LifetimeDatabase<String, EthereumToken>

    public init(provider: KeyAppTokenProvider) {
        self.provider = provider
        database = .init(
            filePath: "ethereum-token",
            storage: ApplicationFileStorage(),
            defaultLifetime: 60 * 60 * 24 * 7
        )
    }

    /// Resolve native token
    public func resolveNativeToken() async throws -> EthereumToken {
        // Load from cache
        if let nativeToken = try await database.read(for: "native") {
            return nativeToken
        }

        // Fetch
        let response = try await provider.getTokensInfo(
            .init(
                query: [
                    .init(chainId: "ethereum", addresses: ["native"]),
                ]
            )
        )

        guard let tokenData = response.first?.data.first else {
            throw Error.nativeTokenCanNotBeResolved
        }

        // Parse and store
        let nativeToken = try parseToken(tokenData: tokenData)
        try? await database.write(for: "native", value: nativeToken)

        return nativeToken
    }

    /// Resolve ERC-20 token by address.
    public func resolve(addresses: [EthereumAddress]) async throws -> [EthereumAddress: EthereumToken] {
        var result: [EthereumAddress: EthereumToken] = [:]

        // Locale storage
        for address in addresses {
            result[address] = try? await database.read(for: address.hex(eip55: false))
        }

        // Build missing list
        var missingTokenAddresses: [String] = []
        for address in addresses {
            if result[address] == nil {
                missingTokenAddresses.append(address.hex(eip55: false))
            }
        }

        // Fetch
        let response = try await provider.getTokensInfo(
            .init(
                query: [
                    .init(chainId: "ethereum", addresses: missingTokenAddresses),
                ]
            )
        )

        // Parse
        let tokens: [EthereumToken] = response.first?.data.compactMap { tokenData in
            do {
                return try parseToken(tokenData: tokenData)
            } catch {
                return nil
            }
        } ?? []

        // Store and fill result
        for token in tokens {
            switch token.contractType {
            case let .erc20(contract):
                result[contract] = token
                try? await database.write(for: contract.hex(eip55: false), value: token)
            default:
                continue
            }
        }

        return result
    }

    public func resolve(address: EthereumAddress) async throws -> EthereumToken? {
        try await resolve(addresses: [address]).values.first
    }

    internal func parseToken(tokenData: KeyAppTokenProviderData.Token) throws -> EthereumToken {
        // Logo
        let logo: URL?
        if let logoUrl = tokenData.logoUrl {
            logo = URL(string: logoUrl)
        } else {
            logo = nil
        }

        // Parse
        return try EthereumToken(
            name: tokenData.name,
            symbol: tokenData.symbol,
            decimals: tokenData.decimals,
            logo: logo,
            contractType: .erc20(contract: EthereumAddress(hex: tokenData.address, eip55: false))
        )
    }
}

public extension EthereumTokensRepository {
    var nativeToken: EthereumToken {
        get async throws {
            try await resolveNativeToken()
        }
    }

    enum Error: Swift.Error {
        case nativeTokenCanNotBeResolved
    }
}
