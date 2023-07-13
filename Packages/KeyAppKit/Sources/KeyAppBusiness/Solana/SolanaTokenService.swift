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
                }
            }
        }

        do {
            let result = try await provider.getSolanaTokens(modifiedSince: Date())
            switch result {
            case .noChanges:
                status = .ready
                return
            case let .result(result):
                // Update database
                database.timestamps = result.timestamp
                let tokens = result.tokens.map { token in
                    (token.address, token)
                }
                database.data = Dictionary(tokens, uniquingKeysWith: { lhs, _ in lhs })
                status = .ready
            }

            if let encodedData = try? JSONEncoder().encode(database) {
                try? await storage.save(for: filename, data: encodedData)
            }
        } catch {
            errorObserver.handleError(error)
        }
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
            try await getOrThrow(address: TokenMetadata.usdc.address)
        }
    }

    // TODO: Wait backend for fix native token
    var nativeToken: SolanaToken {
        get async throws {
            TokenMetadata.nativeSolana
        }
    }
}
