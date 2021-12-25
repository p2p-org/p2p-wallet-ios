//
//  PricesService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol PricesServiceType {
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> {get}
    
    func observePrice(of coinName: String) -> Observable<CurrentPrice?>
    
    func getCurrentPrices() -> [String: CurrentPrice]
    func currentPrice(for coinName: String) -> CurrentPrice?
    func clearCurrentPrices()
    
    func fetchAllTokensPrice()
    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]>
    
    func startObserving()
    func stopObserving()
}

extension PricesServiceType {
    var solPrice: CurrentPrice? {
        currentPrice(for: "SOL")
    }
}

class PricesService {
    enum Error: Swift.Error {
        case notFound
        case unknown
    }
    
    // MARK: - Constants
    private let refreshInterval: TimeInterval = 2 * 60 // 2 minutes
    
    // MARK: - Dependencies
    @Injected private var storage: PricesStorage
    @Injected private var fetcher: PricesFetcher
    
    // MARK: - Properties
    private let tokensRepository: TokensRepository
    private var timer: Timer?
    private lazy var currentPricesSubject = LoadableRelay<[String: CurrentPrice]>(request: .just(storage.retrievePrices()))
    
    // MARK: - Initializer
    init(tokensRepository: TokensRepository) {
        self.tokensRepository = tokensRepository
        
        // reload to get cached prices
        self.currentPricesSubject.reload()
        
        // change request
        self.currentPricesSubject.request = getCurrentPricesRequest()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Methods
    @objc func fetchAllTokensPrice() {
        currentPricesSubject.refresh()
    }
    
    // MARK: - Helpers
    private func getCurrentPricesRequest() -> Single<[String: CurrentPrice]> {
        tokensRepository.getTokensList()
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .flatMap { [weak self] tokens -> Single<[String: CurrentPrice?]> in
                guard let self = self else {throw Error.unknown}
                let coins = tokens.excludingSpecialTokens()
                    .map { token -> String in
                        var symbol = token.symbol
                        if symbol == "renBTC" {symbol = "BTC"}
                        return symbol
                    }
                    .filter {!$0.contains("-") && !$0.contains("/")}
                    .unique
                return self.fetcher.getCurrentPrices(coins: coins, toFiat: Defaults.fiat.code)
                    .map {prices in
                        var prices = prices
                        prices["renBTC"] = prices["BTC"]
                        return prices
                    }
            }
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { [weak self] newPrices in
                guard let self = self else {throw Error.unknown}
                var prices = self.currentPricesSubject.value ?? [:]
                for newPrice in newPrices {
                    prices[newPrice.key] = newPrice.value
                }
                return prices
            }
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .do(onSuccess: {[weak self] newPrices in
                self?.storage.savePrices(newPrices)
            })
    }
}

extension PricesService: PricesServiceType {
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> {
        currentPricesSubject.asDriver()
    }
    
    func observePrice(of coinName: String) -> Observable<CurrentPrice?> {
        currentPricesSubject.valueObservable
            .map {$0?[coinName]}
    }
    
    func getCurrentPrices() -> [String: CurrentPrice] {
        currentPricesSubject.value ?? [:]
    }
    
    func currentPrice(for coinName: String) -> CurrentPrice? {
        currentPricesSubject.value?[coinName]
    }
    
    func clearCurrentPrices() {
        currentPricesSubject.flush()
        currentPricesSubject.accept(storage.retrievePrices(), state: .notRequested)
        storage.savePrices([:])
    }
    
    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]> {
        fetcher.getHistoricalPrice(of: coinName, fiat: Defaults.fiat.code, period: period)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map {prices in
                if prices.count == 0 {throw Error.notFound}
                return prices
            }
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .catch { _ in
                Single.zip(
                    self.fetcher.getHistoricalPrice(of: coinName, fiat: "USD", period: period),
                    self.fetcher.getValueInUSD(fiat: Defaults.fiat.code)
                )
                .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                .map {records, rate in
                    guard let rate = rate else {return []}
                    var records = records
                    for i in 0..<records.count {
                        records[i] = records[i].converting(exchangeRate: rate)
                    }
                    return records
                }
            }
            .observe(on: MainScheduler.instance)
    }
    
    func startObserving() {
        fetchAllTokensPrice()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: {[weak self] _ in
            self?.fetchAllTokensPrice()
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
