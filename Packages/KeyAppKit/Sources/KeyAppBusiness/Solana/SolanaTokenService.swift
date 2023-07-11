//
//  File.swift
//
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import KeyAppKitCore
import SolanaSwift

public typealias SolanaTokensService = TokenRepository

public class KeyAppSolanaTokenRepository: TokenRepository {
    let provider: KeyAppTokenProvider

    public init(provider: KeyAppTokenProvider) {
        self.provider = provider
    }

    public func get(address: String) async throws -> TokenMetadata? {
        let result = try await get(addresses: [address])
        return result.values.first
    }

    public func get(addresses: [String]) async throws -> [String: TokenMetadata] {
        do {
            let result = try await provider.getTokensInfo(
                .init(
                    query: [
                        .init(
                            chainId: "solana",
                            addresses: addresses
                        ),
                    ]
                )
            )

            let transformedData = result
                .first?
                .data
                .map { tokenData -> (String, TokenMetadata) in
                    (
                        tokenData.address,
                        TokenMetadata(
                            _tags: nil,
                            chainId: 0,
                            address: tokenData.address,
                            symbol: tokenData.symbol,
                            name: tokenData.name,
                            decimals: tokenData.decimals,
                            logoURI: tokenData.logoUrl,
                            extensions: nil
                        )
                    )
                } ?? []

            return Dictionary(transformedData) { lhs, _ in lhs }
        } catch {
            print(error)
            throw error
        }
    }

    public func all() async throws -> Set<TokenMetadata> {
        []
    }

    public func reset() async throws {}
}

enum SolanaTokensServiceError {
    case missingPredefineToken
}

private extension SolanaTokensService {
    func getOrThrow(address: String) async throws -> SolanaToken {
        guard let token = try await get(address: address) else {
            throw SolanaTokenListSourceError.invalidTokenlistURL
        }

        return token
    }
}

public extension SolanaTokensService {
    var usdc: SolanaToken {
        get async throws {
            try await getOrThrow(address: TokenMetadata.usdc.address)
        }
    }

    var solana: SolanaToken {
        get async throws {
            try await getOrThrow(address: TokenMetadata.nativeSolana.address)
        }
    }
}
