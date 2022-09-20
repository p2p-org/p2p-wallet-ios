//
//  Preparing.SceneModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation
import Resolver
import RxCocoa
import RxSwift

protocol BuyPreparingSceneModel: BESceneModel {
    func setAmount(value: Double?)
    func swap()

    var inputDriver: Driver<Buy.ExchangeInput> { get }
    var outputDriver: Driver<Buy.ExchangeOutput> { get }
    var minFiatAmount: Driver<Double> { get }
    var minCryptoAmount: Driver<Double> { get }
    var exchangeRateDriver: Driver<Buy.ExchangeRate?> { get }
    var input: Buy.ExchangeInput { get }
    var crypto: Buy.CryptoCurrency { get }
    var amount: Double { get }
    var walletsRepository: WalletsRepository { get }
}

extension BuyPreparing {
    class SceneModel: BuyPreparingSceneModel {
        private let exchangeService: Buy.ExchangeService
        let disposeBag = DisposeBag()

        @Injected var walletsRepository: WalletsRepository

        let crypto: Buy.CryptoCurrency
        private let errorRelay = BehaviorRelay<String?>(value: nil)
        private let inputRelay =
            BehaviorRelay<Buy.ExchangeInput>(value: .init(amount: 0, currency: Buy.FiatCurrency.usd))
        private let outputRelay: BehaviorRelay<Buy.ExchangeOutput>
        private let minFiatAmountsRelay = BehaviorRelay<Double>(value: 0)
        private let minCryptoAmountsRelay = BehaviorRelay<Double>(value: 0)
        private let exchangeRateRelay = BehaviorRelay<Buy.ExchangeRate?>(value: nil)
        private let updateTimer = Observable<Int>
            .timer(.seconds(0), period: .seconds(10), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))

        init(crypto: Buy.CryptoCurrency, exchangeService: Buy.ExchangeService) {
            self.crypto = crypto
            self.exchangeService = exchangeService

            outputRelay = BehaviorRelay<Buy.ExchangeOutput>(
                value: .init(
                    amount: 0,
                    currency: crypto,
                    processingFee: 0,
                    networkFee: 0,
                    purchaseCost: 0,
                    total: 0
                )
            )

            updateTimer
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    Single.zip(
                        self.exchangeService.getExchangeRate(from: .usd, to: crypto),
                        self.exchangeService.getMinAmount(currency: crypto),
                        self.exchangeService.getMinAmount(currency: Buy.FiatCurrency.usd)
                    ).subscribe(onSuccess: { [weak self] exchangeRate, minCryptoAmount, minFiatAmount in
                        self?.exchangeRateRelay.accept(exchangeRate)
                        self?.minCryptoAmountsRelay.accept(minCryptoAmount)

                        let minFiatAmount = max(ceil(minCryptoAmount * exchangeRate.amount), minFiatAmount)
                            .rounded(decimals: 2)
                        self?.minFiatAmountsRelay.accept(minFiatAmount)
                    }).disposed(by: self.disposeBag)
                })
                .disposed(by: disposeBag)

            Observable.combineLatest(inputRelay, updateTimer)
                .flatMapLatest { [weak self] input, _ -> Single<Buy.ExchangeOutput> in
                    guard let self = self else { return .error(NSError(domain: "Preparing", code: -1)) }
                    if input.amount == 0 {
                        return .just(.init(
                            amount: 0,
                            currency: self.outputRelay.value.currency,
                            processingFee: 0,
                            networkFee: 0,
                            purchaseCost: 0,
                            total: 0
                        ))
                    }
                    return self.exchangeService
                        .convert(input: input, to: input.currency is Buy.FiatCurrency ? crypto : Buy.FiatCurrency.usd)
                        .do { [weak self] _ in
                            self?.errorRelay.accept(nil)
                        }
                        .catch { [weak self] error in
                            guard let self = self else { throw error }
                            if let error = error as? Buy.Exception {
                                switch error {
                                case .invalidInput:
                                    self.errorRelay.accept("Invalid input")
                                case let .message(message):
                                    self.errorRelay.accept(message)
                                }

                            } else {
                                self.errorRelay.accept(error.localizedDescription)
                            }
                            return .just(.init(
                                amount: 0,
                                currency: self.outputRelay.value.currency,
                                processingFee: 0,
                                networkFee: 0,
                                purchaseCost: 0,
                                total: 0
                            ))
                        }
                }
                .bind(to: outputRelay)
                .disposed(by: disposeBag)
        }

        func setAmount(value: Double?) {
            if value == input.amount { return }
            // Update amount
            inputRelay.accept(
                .init(
                    amount: value ?? 0,
                    currency: inputRelay.value.currency
                )
            )
        }

        func swap() {
            let (input, output) = inputRelay.value.swap(with: outputRelay.value)
            outputRelay.accept(output)
            inputRelay.accept(input)
        }

        var inputDriver: Driver<Buy.ExchangeInput> { inputRelay.asDriver() }

        var outputDriver: Driver<Buy.ExchangeOutput> { outputRelay.asDriver() }

        var exchangeRateDriver: Driver<Buy.ExchangeRate?> { exchangeRateRelay.asDriver() }

        var input: Buy.ExchangeInput { inputRelay.value }

        var minFiatAmount: Driver<Double> { minFiatAmountsRelay.asDriver() }

        var minCryptoAmount: Driver<Double> { minCryptoAmountsRelay.asDriver() }

        var amount: Double { outputRelay.value.total }
    }
}
