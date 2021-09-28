//
//  PricesManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

protocol PricesStorage {
    func retrievePrices() -> [String: CurrentPrice]
    func savePrices(_ prices: [String: CurrentPrice])
}

class PricesManager {
    enum Error: Swift.Error {
        case notFound
        case unknown
    }
    // MARK: - Properties
    var tokensRepository: TokensRepository
    let pricesStorage: PricesStorage
    var fetcher: PricesFetcher
    private var fetchAllTokenPricesDisposable: Disposable?
    
    private var refreshInterval: TimeInterval // Refresh
    private var timer: Timer?
    
    // MARK: - Subjects
    lazy var currentPrices = BehaviorRelay<[String: CurrentPrice]>(value: pricesStorage.retrievePrices())
    
    // MARK: - Initializer
    init(tokensRepository: TokensRepository, pricesStorage: PricesStorage, fetcher: PricesFetcher, refreshAfter seconds: TimeInterval = 30) {
        self.tokensRepository = tokensRepository
        self.pricesStorage = pricesStorage
        self.fetcher = fetcher
        self.refreshInterval = seconds
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Getters
    func currentPrice(for coinName: String) -> CurrentPrice? {
        currentPrices.value[coinName]
    }
    
    // MARK: - Observe current price
    func startObserving() {
        fetchAllTokensPrice()
        timer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(fetchAllTokensPrice), userInfo: nil, repeats: true)
    }
    
    func stopObserving() {
        timer?.invalidate()
    }
    
    // get supported coin
    
    @objc func fetchAllTokensPrice() {
        // cancel previous request
        fetchAllTokenPricesDisposable?.dispose()
        
        // request new records
        fetchAllTokenPricesDisposable = tokensRepository.getTokensList()
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
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: {[weak self] prices in
                guard let self = self else {return}
                self.updateCurrentPrices(prices)
            }, onFailure: {error in
                Logger.log(message: "Error fetching price \(error)", event: .error)
            })
    }
    
    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]>
    {
        fetcher.getHistoricalPrice(of: coinName, fiat: Defaults.fiat.code, period: period)
            .map {prices in
                if prices.count == 0 {throw Error.notFound}
                return prices
            }
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
//            .do(
//                afterSuccess: {
//                    Logger.log(message: "Historical price for \(coinName) in \(period): \($0)", event: .response)
//                    
//                },
//                afterError: { error in
//                    Logger.log(message: "Historical price fetching error: \(error)", event: .error)
//                }
//            )
    }
}

extension PricesManager {
    func updateCurrentPrices(_ newPrices: [String: CurrentPrice?]) {
        var prices = currentPrices.value
        for newPrice in newPrices {
            prices[newPrice.key] = newPrice.value
        }
        pricesStorage.savePrices(prices)
        currentPrices.accept(prices)
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
