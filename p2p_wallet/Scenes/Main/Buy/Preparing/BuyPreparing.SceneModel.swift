//
//  Preparing.SceneModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation
import RxSwift
import RxCocoa

protocol SolanaBuyTokenSceneModel: BESceneModel {
    func setAmount(value: Double?)
    func swap()
    func back()
    func next()
    
    var inputDriver: Driver<Buy.ExchangeInput> { get }
    var outputDriver: Driver<Buy.ExchangeOutput> { get }
    var minUSDAmount: Driver<Double> { get }
    var minSOLAmount: Driver<Double> { get }
    var exchangeRateDriver: Driver<Buy.ExchangeRate?> { get }
    var errorDriver: Driver<String?> { get }
    var input: Buy.ExchangeInput { get }
}

extension BuyPreparing {
    class SceneModel: SolanaBuyTokenSceneModel {
        private let exchangeService: Buy.ExchangeService
        private let buyViewModel: BuyViewModelType
        let disposeBag = DisposeBag()
        
        init(buyViewModel: BuyViewModelType, exchangeService: Buy.ExchangeService) {
            self.buyViewModel = buyViewModel
            self.exchangeService = exchangeService
            
            exchangeService
                .getExchangeRate(from: .usd, to: .sol)
                .asObservable()
                .bind(to: exchangeRateRelay)
                .disposed(by: disposeBag)
            
            exchangeService
                .getMinAmounts(
                    Buy.FiatCurrency.usd,
                    Buy.CryptoCurrency.sol
                )
                .subscribe(onSuccess: { [weak self] usd, sol in
                    self?.minUSDAmountsRelay.accept(usd)
                    self?.minSolAmountsRelay.accept(sol)
                })
                .disposed(by: disposeBag)
            
            inputRelay
                .flatMap { [weak self] input -> Single<Buy.ExchangeOutput> in
                    guard let self = self else { return .error(NSError(domain: "Preparing", code: -1)) }
                    if input.amount == 0 {
                        return .just(.init(amount: 0, currency: self.outputRelay.value.currency, processingFee: 0, networkFee: 0, total: 0))
                    }
                    return self.exchangeService
                        .convert(input: input, to: input.currency is Buy.FiatCurrency ? Buy.CryptoCurrency.sol : Buy.FiatCurrency.usd)
                        .do { output in
                            self.errorRelay.accept(nil)
                        }
                        .catch { error in
                            if let error = error as? Buy.Exception {
                                switch error {
                                case .invalidInput:
                                    self.errorRelay.accept("Invalid input")
                                case .message(let message):
                                    self.errorRelay.accept(message)
                                }
                                
                            } else {
                                self.errorRelay.accept(error.localizedDescription)
                            }
                            return .just(.init(amount: 0, currency: self.outputRelay.value.currency, processingFee: 0, networkFee: 0, total: 0))
                        }
                }
                .bind(to: outputRelay)
                .disposed(by: disposeBag)
        }
        
        private let errorRelay = BehaviorRelay<String?>(value: nil)
        private let inputRelay = BehaviorRelay<Buy.ExchangeInput>(value: .init(amount: 0, currency: Buy.FiatCurrency.usd))
        private let outputRelay = BehaviorRelay<Buy.ExchangeOutput>(value: .init(amount: 0, currency: Buy.CryptoCurrency.sol, processingFee: 0, networkFee: 0, total: 0))
        private let minSolAmountsRelay = BehaviorRelay<Double>(value: 0)
        private let minUSDAmountsRelay = BehaviorRelay<Double>(value: 0)
        private let exchangeRateRelay = BehaviorRelay<Buy.ExchangeRate?>(value: nil)
        
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
        
        var errorDriver: Driver<String?> { errorRelay.asDriver() }
        
        func next() { buyViewModel.navigate(to: .buyToken(crypto: .sol, amount: outputRelay.value.total)) }
        
        func back() { buyViewModel.navigate(to: .back) }
        
        var minUSDAmount: Driver<Double> { minUSDAmountsRelay.asDriver() }
        
        var minSOLAmount: Driver<Double> { minSolAmountsRelay.asDriver() }
    }
}
