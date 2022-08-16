//
//  PricesService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/11/2021.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaPricesAPIs
import SolanaSwift

protocol PricesServiceType {
    // Observables
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> { get }

    // Getters
    func getWatchList() -> [Token]
    func currentPrice(for coinName: String) -> CurrentPrice?

    // Actions
    func clearCurrentPrices()
    func addToWatchList(_ tokens: [Token])
    func fetchPrices(tokens: [Token])
    func fetchAllTokensPriceInWatchList()
    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]>

    func startObserving()
    func stopObserving()
}

class PricesLoadableRelay: LoadableRelay<[String: CurrentPrice]> {
    override func map(oldData: [String: CurrentPrice]?, newData: [String: CurrentPrice]) -> [String: CurrentPrice] {
        guard var data = oldData else {
            return newData
        }

        for key in newData.keys {
            data[key] = newData[key]
        }
        return data
    }
}

class PricesService {
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

    private var watchList = [Token(.renBTC), Token(.nativeSolana), Token(.usdc)]
    private var timer: Timer?
    private lazy var currentPricesSubject = PricesLoadableRelay(request: .just([:]))

    // MARK: - Initializer

    init() {
        // reload to get cached prices
        currentPricesSubject.reload()

        // get current price
        Task {
            var initialValue = await storage.retrievePrices()
            if initialValue.values.isEmpty {
                initialValue = try await getCurrentPrices()
            }
            currentPricesSubject.accept(initialValue, state: .loaded)

            // change request
            currentPricesSubject.request = getCurrentPricesRequest()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Helpers

    private func getCurrentPricesRequest(tokens: [Token]? = nil) -> Single<[String: CurrentPrice]> {
        Single.async {
            try await self.getCurrentPrices(tokens: tokens)
        }
    }

    private func getCurrentPrices(tokens: [Token]? = nil) async throws -> [String: CurrentPrice] {
        let coins = (tokens ?? watchList).filter { !$0.symbol.contains("-") && !$0.symbol.contains("/") }
            .map { token -> Token in
                if token.symbol == "renBTC" {
                    return Token(token, customSymbol: "BTC")
                }
                return token
            }
            .unique
        guard !coins.isEmpty else {
            return [:]
        }

        var newPrices = try await api.getCurrentPrices(coins: coins, toFiat: Defaults.fiat.code)
        newPrices["renBTC"] = newPrices["BTC"]
        var prices = currentPricesSubject.value ?? [:]
        for newPrice in newPrices {
            prices[newPrice.key] = newPrice.value
        }
        await storage.savePrices(prices)
        return prices
    }
}

extension PricesService: PricesServiceType {
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> {
        currentPricesSubject.asDriver()
    }

    func getWatchList() -> [Token] {
        watchList
    }

    func currentPrice(for coinName: String) -> CurrentPrice? {
        currentPricesSubject.value?[coinName.uppercased()]
    }

    func clearCurrentPrices() {
        currentPricesSubject.flush()

        Task {
            await storage.savePrices([:])
        }
    }

    func addToWatchList(_ tokens: [Token]) {
        for token in tokens {
            watchList.appendIfNotExist(token)
        }
    }

    func fetchPrices(tokens: [Token]) {
        guard !tokens.isEmpty else { return }
        currentPricesSubject.request = getCurrentPricesRequest(tokens: tokens)
        currentPricesSubject.refresh()
    }

    func fetchAllTokensPriceInWatchList() {
        guard !watchList.isEmpty else { return }
        fetchPrices(tokens: watchList)
    }

    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]> {
        Single.async { [weak self] in
            guard let self = self else { throw Error.unknown }
            do {
                let prices = try await self.api.getHistoricalPrice(
                    of: coinName,
                    fiat: Defaults.fiat.code,
                    period: period
                )
                if prices.isEmpty { throw Error.notFound }
                return prices
            } catch {
                if Defaults.fiat.code.uppercased() != "USD" {
                    // retry with different fiat
                    async let pricesInUSD = self.api.getHistoricalPrice(of: coinName, fiat: "USD", period: period)
                    async let valueInUSD = self.api.getValueInUSD(fiat: Defaults.fiat.code)

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
        .observe(on: MainScheduler.instance)
    }

    func startObserving() {
        fetchAllTokensPriceInWatchList()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { [weak self] _ in
            self?.fetchAllTokensPriceInWatchList()
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
