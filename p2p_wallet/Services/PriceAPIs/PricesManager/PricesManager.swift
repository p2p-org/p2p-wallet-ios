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
    }
    // MARK: - Properties
    var tokensRepository: TokensRepository
    let pricesStorage: PricesStorage
    var fetcher: PricesFetcher
    private let disposeBag = DisposeBag()
    
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
    func fetchCurrentPrices(coins: [String] = []) {
        fetcher.getCurrentPrices(coins: coins, toFiat: Defaults.fiat.code)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: {[weak self] prices in
                guard let self = self else {return}
                self.updateCurrentPrices(prices)
            }, onFailure: {error in
                Logger.log(message: "Error fetching price \(error)", event: .error)
            })
            .disposed(by: disposeBag)
    }
    
    @objc func fetchAllTokensPrice() {
        tokensRepository.getTokensList()
            .subscribe(onSuccess: {[weak self] tokens in
                let coins = tokens.excludingSpecialTokens()
                    .map {$0.symbol}
                self?.fetchCurrentPrices(coins: coins)
            })
            .disposed(by: disposeBag)
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
