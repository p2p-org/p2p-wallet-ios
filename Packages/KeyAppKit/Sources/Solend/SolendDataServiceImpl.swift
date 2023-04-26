// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Foundation
import P2PSwift
import SolanaSwift

private struct SolendDataCache: Codable {
    let userPublicAddress: String
    let assets: [SolendConfigAsset]?
    let deposits: [SolendUserDeposit]?
    let marketInfos: [SolendMarketInfo]?
    let lastUpdate: Date?
}

public class SolendDataServiceImpl: SolendDataService {
    // Variables
    private let solend: Solend
    private var owner: Account
    private var lendingMark: String
    private let cache: SolendCache

    private let allowedSymbols = ["USDC", "USDT"]

    // Subjects
    private let errorSubject: CurrentValueSubject<Error?, Never> = .init(nil)
    public var error: AnyPublisher<Error?, Never> {
        errorSubject
            .eraseToAnyPublisher()
    }

    private let statusSubject: CurrentValueSubject<SolendDataStatus, Never> = .init(.initialized)
    public var status: AnyPublisher<SolendDataStatus, Never> {
        statusSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let availableAssetsSubject: CurrentValueSubject<[SolendConfigAsset]?, Never> = .init(nil)
    public var availableAssets: AnyPublisher<[SolendConfigAsset]?, Never> {
        availableAssetsSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let depositsSubject: CurrentValueSubject<[SolendUserDeposit]?, Never> = .init([])
    public var deposits: AnyPublisher<[SolendUserDeposit]?, Never> {
        depositsSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let marketInfoSubject: CurrentValueSubject<[SolendMarketInfo]?, Never> = .init([])
    public var marketInfo: AnyPublisher<[SolendMarketInfo]?, Never> {
        marketInfoSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let lastUpdateDateSubject: CurrentValueSubject<Date, Never> = .init(Date())
    public var lastUpdateDate: AnyPublisher<Date, Never> {
        lastUpdateDateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // Cache service
    private static let CacheKey = "SolendDataServiceCache"
    private var dataCache: SolendDataCache? {
        set {
            if let newValue = newValue {
                cache.write(newValue, for: Self.CacheKey)
            } else {
                cache.delete(Self.CacheKey)
            }
        }

        get {
            cache.read(type: SolendDataCache.self, Self.CacheKey)
        }
    }

    public init(solend: Solend, owner: Account, lendingMark: String, cache: SolendCache? = nil) {
        self.solend = solend
        self.owner = owner
        self.lendingMark = lendingMark
        self.cache = cache ?? SolendInMemoryCache()

        if let dataCache: SolendDataCache = dataCache {
            let interval = DateInterval(start: dataCache.lastUpdate ?? Date(), end: Date())
            if dataCache.userPublicAddress == owner.publicKey.base58EncodedString, interval.duration < 60 * 10 {
                availableAssetsSubject.send(dataCache.assets)
                marketInfoSubject.send(dataCache.marketInfos)
                depositsSubject.send(dataCache.deposits)
                lastUpdateDateSubject.send(dataCache.lastUpdate ?? Date())
            } else {
                self.dataCache = nil
            }
        }

        Task.detached { try await self.update() }
    }

    public var hasDeposits: Bool {
        depositsSubject.value?.first { (Double($0.depositedAmount) ?? 0) > 0 } != nil
    }

    public func clearDeposits() {
        depositsSubject.send(nil)
    }

    public func update() async throws {
        do {
            guard statusSubject.value != .updating else { return }

            // Setup status and clear error
            statusSubject.send(.updating)
            defer { statusSubject.send(.ready) }
            errorSubject.send(nil)

            // Update available assets and user deposits
            let _ = await(
                try updateConfig(),
                try updateUserDeposits()
            )

            // Update market info
            try await updateMarketInfo()

            dataCache = .init(
                userPublicAddress: owner.publicKey.base58EncodedString,
                assets: availableAssetsSubject.value,
                deposits: depositsSubject.value,
                marketInfos: marketInfoSubject.value,
                lastUpdate: lastUpdateDateSubject.value
            )
        } catch {
            print(error)
            errorSubject.send(error)
            statusSubject.send(.ready)
        }
    }

    private func updateConfig() async throws {
        do {
            let config: SolendConfig = try await solend.getConfig(environment: .production)

            // Filter and fix usdt logo
            let filteredAssets = config.assets
                .filter { allowedSymbols.contains($0.symbol) }
                .map { asset -> SolendConfigAsset in
                    switch asset.symbol {
                    case "USDT":
                        return asset
                            .copy(
                                logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/BQcdHdAQW1hczDbBi9hiegXAR7A98Q9jx3X3iBBBDiq4/logo.png"
                            )
                    case "SOL":
                        return asset.copy(name: "Solana")
                    default:
                        return asset
                    }
                }

            if availableAssetsSubject.value != filteredAssets {
                lastUpdateDateSubject.send(Date())
            }

            availableAssetsSubject.send(filteredAssets)
        } catch {
            errorSubject.send(error)
            throw error
        }
    }

    private func updateMarketInfo() async throws {
        guard let availableAssets = availableAssetsSubject.value else {
            marketInfoSubject.send(nil)
            return
        }

        do {
            let marketInfo = try await solend
                .getMarketInfo(symbols: availableAssets.map(\.symbol), pool: "main")
                .map { token, marketInfo -> SolendMarketInfo in .init(
                    symbol: token,
                    currentSupply: marketInfo.currentSupply,
                    depositLimit: marketInfo.currentSupply,
                    supplyInterest: marketInfo.supplyInterest
                ) }
            marketInfoSubject.send(marketInfo)
        } catch {
            marketInfoSubject.send(nil)
            errorSubject.send(error)
            throw error
        }
    }

    private func updateUserDeposits() async throws {
        do {
            let userDeposits = try await solend.getUserDeposits(
                owner: owner.publicKey.base58EncodedString,
                pool: "main"
            )
            depositsSubject.send(userDeposits)
        } catch {
            // Check error
            switch error as? SolendError {
            case let .message(msg):
                if msg == "Pool is empty" {
                    depositsSubject.send([])
                    return
                }
            default:
                break
            }

            // Throw error
            depositsSubject.send(nil)
            errorSubject.send(error)
            throw error
        }
    }
}
