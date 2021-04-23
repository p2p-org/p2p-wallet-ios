//
//  PricesManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

class PricesManager {
    // MARK: - Properties
    var tokensRepository: TokensRepository
    var fetcher: PricesFetcher
    private let disposeBag = DisposeBag()
    
    private var refreshInterval: TimeInterval // Refresh
    private var timer: Timer?
    
    // MARK: - Subjects
    let currentPrices = BehaviorRelay<[String: CurrentPrice]>(value: [:])
    
    // MARK: - Initializer
    init(tokensRepository: TokensRepository, fetcher: PricesFetcher, refreshAfter seconds: TimeInterval = 30) {
        self.tokensRepository = tokensRepository
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
        fetchCurrentPrices()
        timer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(fetchCurrentPrices), userInfo: nil, repeats: true)
    }
    
    func stopObserving() {
        timer?.invalidate()
    }
    
    // get supported coin
    @objc func fetchCurrentPrices() {
        fetcher.getCurrentPrices(coins: tokensRepository.supportedTokens.map {$0.symbol}, toFiat: Defaults.fiat.code)
            .subscribe(onSuccess: {[weak self] prices in
                guard let self = self else {return}
                self.updateCurrentPrices(prices)
            }, onFailure: {error in
                Logger.log(message: "Error fetching price \(error)", event: .error)
            })
            .disposed(by: disposeBag)
    }
    
    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]>
    {
        fetcher.getHistoricalPrice(of: coinName, fiat: Defaults.fiat.code, period: period)
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
        currentPrices.accept(prices)
    }
}
