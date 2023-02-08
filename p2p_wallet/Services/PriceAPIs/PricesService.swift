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

typealias TokenPriceMap = [String: CurrentPrice]

protocol PricesServiceType {
    // Observables
    var currentPricesDriver: Driver<Loadable<TokenPriceMap>> { get }

    // Getters
    func getWatchList() -> [Token]
    func currentPrice(mint: String) -> CurrentPrice?

    // Actions
    func clearCurrentPrices()
    func addToWatchList(_ tokens: [Token])
    func fetchPrices(tokens: [Token], toFiat: Fiat)
    func fetchAllTokensPriceInWatchList()
    func getCurrentPrices(tokens: [Token]?, toFiat: Fiat) async throws -> TokenPriceMap
    func startObserving()
    func stopObserving()
}

class PricesLoadableRelay: LoadableRelay<[String: CurrentPrice]> {
    override func map(oldData: TokenPriceMap?, newData: TokenPriceMap) -> TokenPriceMap {
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

    private var watchList = [
        Token(.renBTC), Token(.nativeSolana), Token(.usdc), Token(.eth), Token(.usdt),
    ]
    private var timer: Timer?
    private lazy var currentPricesSubject = PricesLoadableRelay(request: .just([:]))

    // MARK: - Initializer

    init() {
        // reload to get cached prices
        currentPricesSubject.reload()

        // get current price
        Task {
            // migration
            await migrate()
            
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
    
    private func migrate() async {
        // First migration to fix COPE token
        let migration1Key = "PricesService.migration1Key"
        
        if UserDefaults.standard.bool(forKey: migration1Key) == false {
            // clear current cache
            await storage.savePrices([:])
            
            // mark as migrated
            UserDefaults.standard.set(true, forKey: migration1Key)
        }
    }

    private func getCurrentPricesRequest(
        tokens: [Token]? = nil,
        toFiat: Fiat = Defaults.fiat
    ) -> Single<TokenPriceMap> {
        Single.async {
            try await self.getCurrentPrices(tokens: tokens, toFiat: toFiat)
        }
    }

    func getCurrentPrices(tokens: [Token]? = nil, toFiat: Fiat = Defaults.fiat) async throws -> TokenPriceMap {
        let coins: [Token] = (tokens ?? watchList)
            .filter { !$0.symbol.contains("-") && !$0.symbol.contains("/") }
            .unique
        guard !coins.isEmpty else {
            return [:]
        }

        let newPrices = try await api.getCurrentPrices(coins: coins, toFiat: toFiat.code)
        var prices = currentPricesSubject.value ?? [:]
        for newPrice in newPrices {
            prices[newPrice.key.address] = newPrice.value
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

    func currentPrice(mint: String) -> CurrentPrice? {
        currentPricesSubject.value?[mint]
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

    func fetchPrices(tokens: [Token], toFiat: Fiat = Defaults.fiat) {
        guard !tokens.isEmpty else { return }
        currentPricesSubject.request = getCurrentPricesRequest(
            tokens: tokens,
            toFiat: toFiat
        )
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
