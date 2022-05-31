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
import SolanaSwift

protocol PricesServiceType {
    // Observables
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> { get }

    // Getters
    func getWatchList() -> [String]
    func currentPrice(for coinName: String) -> CurrentPrice?

    // Actions
    func clearCurrentPrices()
    func addToWatchList(_ tokens: [String])
    func fetchPrices(tokens: [String])
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
    @Injected private var fetcher: PricesFetcher

    // MARK: - Properties

    private var watchList = [String]()
    private var timer: Timer?
    private lazy var currentPricesSubject = PricesLoadableRelay(request: .just(storage.retrievePrices()))

    // MARK: - Initializer

    init() {
        // reload to get cached prices
        currentPricesSubject.reload()

        // change request
        currentPricesSubject.request = getCurrentPricesRequest()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Helpers

    private func getCurrentPricesRequest(tokens: [String]? = nil) -> Single<[String: CurrentPrice]> {
        let coins = (tokens ?? watchList).map { token -> String in
            if token == "renBTC" {
                return "BTC"
            }
            return token
        }
        .unique
        .filter { !$0.contains("-") && !$0.contains("/") }

        guard !coins.isEmpty else {
            return .just([:])
        }

        return fetcher.getCurrentPrices(coins: coins, toFiat: Defaults.fiat.code)
            .map { prices -> [String: CurrentPrice?] in
                var prices = prices
                prices["renBTC"] = prices["BTC"]
                return prices
            }
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { [weak self] newPrices in
                guard let self = self else { throw Error.unknown }
                var prices = self.currentPricesSubject.value ?? [:]
                for newPrice in newPrices {
                    prices[newPrice.key] = newPrice.value
                }
                return prices
            }
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .do(onSuccess: { [weak self] newPrices in
                self?.storage.savePrices(newPrices)
            })
    }
}

extension PricesService: PricesServiceType {
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> {
        currentPricesSubject.asDriver()
    }

    func getWatchList() -> [String] {
        watchList
    }

    func currentPrice(for coinName: String) -> CurrentPrice? {
        currentPricesSubject.value?[coinName]
    }

    func clearCurrentPrices() {
        currentPricesSubject.flush()
        storage.savePrices([:])
    }

    func addToWatchList(_ tokens: [String]) {
        for token in tokens {
            watchList.appendIfNotExist(token)
        }
    }

    func fetchPrices(tokens: [String]) {
        guard !tokens.isEmpty else { return }
        currentPricesSubject.request = getCurrentPricesRequest(tokens: tokens)
        currentPricesSubject.refresh()
    }

    func fetchAllTokensPriceInWatchList() {
        guard !watchList.isEmpty else { return }
        fetchPrices(tokens: watchList)
    }

    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]> {
        fetcher.getHistoricalPrice(of: coinName, fiat: Defaults.fiat.code, period: period)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { prices in
                if prices.isEmpty { throw Error.notFound }
                return prices
            }
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .catch { [weak self] _ in
                guard let self = self else { throw SolanaError.unknown }
                return Single.zip(
                    self.fetcher.getHistoricalPrice(of: coinName, fiat: "USD", period: period),
                    self.fetcher.getValueInUSD(fiat: Defaults.fiat.code)
                )
                    .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                    .map { records, rate in
                        guard let rate = rate else { return [] }
                        var records = records
                        for i in 0 ..< records.count {
                            records[i] = records[i].converting(exchangeRate: rate)
                        }
                        return records
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
