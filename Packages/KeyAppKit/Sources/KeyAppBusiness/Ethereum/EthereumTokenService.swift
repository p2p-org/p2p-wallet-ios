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
    let cache: Cache<EthereumAddress, EthereumToken> = .init()

    /// Some tokens contains low quality image and bad name. This class apply some changes to token metadata.
    let dataCorrection: EthereumTokenDataCorrection = .init()

    public init(provider: KeyAppTokenProvider) {
        self.provider = provider
    }

    /// Resolve ERC-20 token by address.
    public func resolve(addresses: [EthereumAddress]) async throws -> [EthereumAddress: EthereumToken] {
        var result: [EthereumAddress: EthereumToken] = [:]

        for address in addresses {
            result[address] = await cache.value(forKey: address)
        }

        var missingTokenAddresses: [String] = []
        for address in addresses {
            if result[address] == nil {
                missingTokenAddresses.append(address.hex(eip55: false))
            }
        }

        let response = try await provider.getTokensInfo(
            .init(
                query: [
                    .init(chainId: "ethereum", addresses: missingTokenAddresses),
                ]
            )
        )

        let tokens: [EthereumToken] = response.first?.data.compactMap { tokenData in
            do {
                let logo: URL?
                if let logoUrl = tokenData.logoUrl {
                    logo = URL(string: logoUrl)
                } else {
                    logo = nil
                }

                return try EthereumToken(
                    name: tokenData.name,
                    symbol: tokenData.symbol,
                    decimals: tokenData.decimals,
                    logo: logo,
                    contractType: .erc20(contract: EthereumAddress(hex: tokenData.address, eip55: false))
                )
            } catch {
                return nil
            }
        } ?? []

        for token in tokens {
            switch token.contractType {
            case let .erc20(contract):
                result[contract] = token
                await cache.insert(token, forKey: contract)
            default:
                continue
            }
        }

        return result
    }

    public func resolve(address: EthereumAddress) async throws -> EthereumToken? {
        try await resolve(addresses: [address]).values.first
    }
}

extension EthereumTokensRepository {
    enum Error: Swift.Error {}
}
