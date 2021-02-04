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
    private let coinToCompare = "USDT"
    private let disposeBag = DisposeBag()
    var fetcher: PricesFetcher
    let currentPrices = BehaviorRelay<[Coin: CurrentPrice]>(value: [:])
    private var refreshInterval: TimeInterval // Refresh
    var solPrice: CurrentPrice? {currentPrices.value["SOL"]}
    private lazy var supportedCoins: [String] = {
        var pairs = SolanaSDK.Token.getSupportedTokens(network: SolanaSDK.Network.mainnetBeta)?.map {$0.symbol}.filter {$0 != "USDT" && $0 != "USDC" && $0 != "WUSDC"} ?? [String]()
        pairs.append("SOL")
        return pairs
    }()
    
    private var timer: Timer?
    
    // MARK: - Initializer
    init(fetcher: PricesFetcher, refreshAfter seconds: TimeInterval = 30) {
        self.fetcher = fetcher
        self.refreshInterval = seconds
        self.updatePriceForUSDType()
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
        for coin in supportedCoins {
            fetcher.getCurrentPrice(from: coin, to: coinToCompare)
                .subscribe(onSuccess: {[weak self] price in
                    self?.updateCurrentPrices([coin: price])
                }, onError: {error in
                    Logger.log(message: "Error fetching price \(error)", event: .error)
                })
                .disposed(by: disposeBag)
        }
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
    func updatePriceForUSDType() {
        var prices = currentPrices.value
        prices["USDT"] = CurrentPrice(value: 1)
        prices["USDC"] = CurrentPrice(value: 1)
        prices["WUSDC"] = CurrentPrice(value: 1)
        currentPrices.accept(prices)
    }
    
    func updateCurrentPrices(_ newPrices: [Coin: CurrentPrice]) {
        var prices = currentPrices.value
        for newPrice in newPrices {
            prices[newPrice.key] = newPrice.value
        }
        currentPrices.accept(prices)
    }
}
