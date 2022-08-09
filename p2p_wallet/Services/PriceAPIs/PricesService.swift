//
//  PricesService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/11/2021.
//

import Combine
import Foundation
import Resolver
import SolanaPricesAPIs
import SolanaSwift

protocol PricesServiceType {
    // Observables
    var currentPricesPublisher: AnyPublisher<[String: CurrentPrice], Never> { get }
    var statePublisher: AnyPublisher<LoadableState, Never> { get }

    // Getters
    func getWatchList() async -> [Token]
    func currentPrice(for coinName: String) -> CurrentPrice?

    // Actions
    func clearCurrentPrices() async
    func addToWatchList(_ tokens: [Token]) async
    func fetchPrices(tokens: [Token]) async throws
    func fetchAllTokensPriceInWatchList() async throws
    func fetchHistoricalPrice(for coinName: String, period: Period) async throws -> [PriceRecord]

    func startObserving() async
    func stopObserving()
}

class PricesService: ObservableObject {
    enum Error: Swift.Error {
        case notFound
        case unknown
    }

    // MARK: - Constants

    private let refreshInterval: TimeInterval = 15 * 60 // 15 minutes

    // MARK: - Dependencies

    @Injected private var storage: PricesStorage
    @Injected private var api: SolanaPricesAPI

    // MARK: - Properties

    @MainActor private var watchList = [Token]()
    private var timer: Timer?
    @Published private var currentPrices = [String: CurrentPrice]()
    @Published private var state = LoadableState.notRequested

    // MARK: - Initializer

    init() {
        // get current price
        Task {
            currentPrices = await storage.retrievePrices()
            state = .loaded
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Helpers

    private func getCurrentPrices(tokens: [Token]? = nil) async throws {
        // set state as loading
        state = .loading

        // get coins to fetch prices
        let watchList = await self.watchList
        let coins = (tokens ?? watchList).filter { !$0.symbol.contains("-") && !$0.symbol.contains("/") }
            .map { token -> Token in
                if token.symbol == "renBTC" {
                    return Token(token, customSymbol: "BTC")
                }
                return token
            }
            .unique

        // if empty, just return
        guard !coins.isEmpty else {
            state = .loaded
            return
        }

        // get new prices
        var newPrices = try await api.getCurrentPrices(coins: coins, toFiat: Defaults.fiat.code)
        newPrices["renBTC"] = newPrices["BTC"]
        var prices = currentPrices
        for newPrice in newPrices {
            prices[newPrice.key] = newPrice.value
        }

        // save to storage
        await storage.savePrices(prices)

        // update
        currentPrices = prices
        state = .loaded
    }
}

extension PricesService: PricesServiceType {
    var currentPricesPublisher: AnyPublisher<[String: CurrentPrice], Never> {
        $currentPrices.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<LoadableState, Never> {
        $state.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    func getWatchList() async -> [Token] {
        await watchList
    }

    func currentPrice(for coinName: String) -> CurrentPrice? {
        currentPrices[coinName]
    }

    func clearCurrentPrices() async {
        currentPrices = [:]
        state = .notRequested
        await storage.savePrices([:])
    }

    @MainActor func addToWatchList(_ tokens: [Token]) {
        for token in tokens {
            watchList.appendIfNotExist(token)
        }
    }

    func fetchPrices(tokens: [Token]) async throws {
        guard !tokens.isEmpty else { return }
        try await getCurrentPrices()
    }

    func fetchAllTokensPriceInWatchList() async throws {
        let watchList = await watchList
        guard watchList.isEmpty else { return }
        try await fetchPrices(tokens: watchList)
    }

    func fetchHistoricalPrice(for coinName: String, period: Period) async throws -> [PriceRecord] {
        do {
            let prices = try await api.getHistoricalPrice(
                of: coinName,
                fiat: Defaults.fiat.code,
                period: period
            )
            if prices.isEmpty { throw Error.notFound }
            return prices
        } catch {
            if Defaults.fiat.code.uppercased() != "USD" {
                // retry with different fiat
                async let pricesInUSD = api.getHistoricalPrice(of: coinName, fiat: "USD", period: period)
                async let valueInUSD = api.getValueInUSD(fiat: Defaults.fiat.code)

                guard let rate = try await valueInUSD else { return [] }
                var records = try await pricesInUSD
                for i in 0 ..< records.count {
                    records[i] = records[i].converting(exchangeRate: rate)
                }
                return records
            }
            throw error
        }
    }

    func startObserving() async {
        try? await fetchAllTokensPriceInWatchList()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { _ in
            Task { [weak self] in
                try? await self?.fetchAllTokensPriceInWatchList()
            }
        })
    }

    func stopObserving() {
        timer?.invalidate()
    }
}

private extension Array where Element: Equatable {
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            guard !uniqueValues.contains(item) else { return }
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}

extension Token {
    init(_ token: Token, customSymbol: String? = nil) {
        self = Token(
            _tags: nil,
            chainId: token.chainId,
            address: token.address,
            symbol: customSymbol ?? token.symbol,
            name: token.name,
            decimals: token.decimals,
            logoURI: token.logoURI,
            extensions: token.extensions
        )
    }
}
