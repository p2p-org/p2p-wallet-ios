import Foundation
import KeyAppKitCore
import SolanaSwift

public typealias SolanaTokensService = TokenRepository

public actor KeyAppSolanaTokenRepository: TokenRepository {
    static let version: Int = 1

    struct Database: Codable, Hashable {
        var timestamps: Date?
        var data: [String: SolanaToken]
        var version: Int?
    }

    enum Status: Int {
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
                    if let migratedDatabase = migrate(database: database) {
                        self.database = migratedDatabase
                        setupStaticToken(data: migratedDatabase.data)
                    }
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
                database.version = Self.version
                database.data = data
                setupStaticToken(data: data)
                status = .ready
            }

            if let encodedData = try? JSONEncoder().encode(database) {
                try? await storage.save(for: filename, data: encodedData)
            }
        } catch {
            errorObserver.handleError(error)
        }
    }

    func migrate(database: Database) -> Database? {
        switch database.version {
        case .none:
            return nil
        case 1:
            return database
        default:
            return database
        }
    }

    public func setupStaticToken(data: [String: TokenMetadata]) {
        TokenMetadata.nativeSolana = data["native"]?.fixedForNativeSOL ?? TokenMetadata.nativeSolana
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
                result["native"] = nativeToken.fixedForNativeSOL
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
            throw APIClientError.invalidAPIURL
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

private extension TokenMetadata {
    var fixedForNativeSOL: Self {
        let wrongMintReturnedFromBackend = "native"
        let fixedMint = "So11111111111111111111111111111111111111112"

        // assert native sol, otherwise don't touch it
        guard mintAddress == wrongMintReturnedFromBackend ||
            mintAddress == fixedMint
        else {
            return self
        }

        // fix the mint
        return SolanaToken(
            tags: tags.map(\.name),
            chainId: chainId,
            mintAddress: "So11111111111111111111111111111111111111112",
            symbol: symbol,
            name: name,
            decimals: decimals,
            logoURI: logoURI,
            extensions: extensions,
            isNative: true
        )
    }
}
