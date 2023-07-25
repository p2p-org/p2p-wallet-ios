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

public actor KeyAppSolanaTokenRepository: TokenRepository {
    internal struct Database: Codable, Hashable {
        var timestamps: Date?
        var data: [String: SolanaToken]
    }

    internal enum Status: Int {
        case initialising = 0
        case updating
        case ready
    }

    let provider: KeyAppTokenProvider

    let filename: String = "solana-token"
    let storage: ApplicationFileStorage = .init()

    var database: Database = .init(timestamps: nil, data: [:])

    let errorObserver: ErrorObserver

    var status: Status = .initialising

    public init(provider: KeyAppTokenProvider, errorObserver: ErrorObserver) {
        self.provider = provider
        self.errorObserver = errorObserver
    }

    public func setup() async {
        guard status != .ready else {
            return
        }

        // Load from local storage
        if status == Status.initialising {
            if let encodedData = try? await storage.load(for: filename) {
                if let database = try? JSONDecoder().decode(Database.self, from: encodedData) {
                    self.database = database
                    setupStaticToken(data: database.data)
                }
            }
        }

        do {
            let result = try await provider.getSolanaTokens(modifiedSince: database.timestamps)
            switch result {
            case .noChanges:
                status = .ready
                return
            case let .result(result):
                // Update database
                database.timestamps = result.timestamp
                let tokens = result.tokens.map { token in
                    (token.mintAddress, token)
                }
                let data = Dictionary(tokens, uniquingKeysWith: { lhs, _ in lhs })
                database.data = data
                setupStaticToken(data: data)
                status = .ready
            }

            if let encodedData = try? JSONEncoder().encode(database) {
                try? await storage.save(for: filename, data: encodedData)
            }
        } catch {
            print(error)
            errorObserver.handleError(error)
        }
    }

    public func setupStaticToken(data: [String: TokenMetadata]) {
        TokenMetadata.nativeSolana = data["native"] ?? TokenMetadata.nativeSolana
        TokenMetadata.usdc = data[PublicKey.usdcMint.base58EncodedString] ?? TokenMetadata.usdc
        TokenMetadata.usdt = data[PublicKey.usdtMint.base58EncodedString] ?? TokenMetadata.usdt
        TokenMetadata.eth = data[TokenMetadata.eth.mintAddress] ?? TokenMetadata.eth
        TokenMetadata.usdcet = data[TokenMetadata.usdcet.mintAddress] ?? TokenMetadata.usdcet
        TokenMetadata.renBTC = data[TokenMetadata.renBTC.mintAddress] ?? TokenMetadata.renBTC
    }

    public func get(address: String) async throws -> TokenMetadata? {
        let result = try await get(addresses: [address])
        return result.values.first
    }

    public func get(addresses: [String]) async throws -> [String: TokenMetadata] {
        await setup()

        var result: [String: TokenMetadata] = [:]
        for address in addresses {
            result[address] = database.data[address]

            // Special case handling for native token
            if let nativeToken = result["native"] {
                result["native"] = SolanaToken(
                    _tags: [],
                    chainId: nativeToken.chainId,
                    mintAddress: "So11111111111111111111111111111111111111112",
                    symbol: nativeToken.symbol,
                    name: nativeToken.name,
                    decimals: nativeToken.decimals,
                    logoURI: nativeToken.logoURI,
                    extensions: nativeToken.extensions,
                    isNative: true
                )
            }
        }

        return result
    }

    public func all() async throws -> [String: TokenMetadata] {
        database.data
    }

    public func reset() async throws {
        database = .init(data: [:])
        if let encodedData = try? JSONEncoder().encode(database) {
            try? await storage.save(for: filename, data: encodedData)
        }

        status = .initialising
    }
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
            try await getOrThrow(address: PublicKey.usdcMint.base58EncodedString)
        }
    }

    var usdt: SolanaToken {
        get async throws {
            try await getOrThrow(address: PublicKey.usdtMint.base58EncodedString)
        }
    }

    var eth: SolanaToken {
        get async throws {
            try await getOrThrow(address: TokenMetadata.eth.mintAddress)
        }
    }

    var usdcet: SolanaToken {
        get async throws {
            try await getOrThrow(address: TokenMetadata.usdcet.mintAddress)
        }
    }

    var rentBTC: SolanaToken {
        get async throws {
            try await getOrThrow(address: TokenMetadata.renBTC.mintAddress)
        }
    }

    var nativeToken: SolanaToken {
        get async throws {
            try await getOrThrow(address: "native")
        }
    }
}
