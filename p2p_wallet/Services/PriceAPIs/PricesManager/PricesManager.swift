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
    typealias Coin = String
    
    // MARK: - Properties
    var fetcher: PricesFetcher
    private let disposeBag = DisposeBag()
    
    private var refreshInterval: TimeInterval // Refresh
    private var timer: Timer?
    var solPrice: CurrentPrice? {currentPrices.value["SOL"]}
    
    private lazy var supportedCoins: [String] = {
        var pairs = SolanaSDK.Token.getSupportedTokens(network: SolanaSDK.Network.mainnetBeta)?.map {$0.symbol} ?? [String]()
        pairs.append("SOL")
        return pairs
    }()
    
    // MARK: - Subjects
    let currentPrices = BehaviorRelay<[Coin: CurrentPrice]>(value: [:])
    
    // MARK: - Initializer
    init(fetcher: PricesFetcher, refreshAfter seconds: TimeInterval = 30) {
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
        fetcher.getCurrentPrices(coins: supportedCoins, toFiat: Defaults.fiat.code)
            .subscribe(onSuccess: {[weak self] prices in
                guard let self = self else {return}
                for (index, coin) in self.supportedCoins.enumerated() {
                    self.updateCurrentPrices([coin: prices[index]])
                }
            }, onError: {error in
                Logger.log(message: "Error fetching price \(error)", event: .error)
            })
            .disposed(by: disposeBag)
    }
    
    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]>
    {
        fetcher.getHistoricalPrice(of: coinName, period: period)
            .do(
                afterSuccess: {
                    Logger.log(message: "Historical price for \(coinName) in \(period): \($0)", event: .response)
                    
                },
                afterError: { error in
                    Logger.log(message: "Historical price fetching error: \(error)", event: .error)
                }
            )
    }
}

extension PricesManager {
    func updateCurrentPrices(_ newPrices: [Coin: CurrentPrice]) {
        var prices = currentPrices.value
        for newPrice in newPrices {
            prices[newPrice.key] = newPrice.value
        }
        currentPrices.accept(prices)
    }
}
