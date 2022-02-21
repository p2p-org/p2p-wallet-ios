//
//  SolanaBuyToken.SceneModel.swift
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
    var exchangeRateDriver: Driver<Buy.ExchangeRate?> { get }
    var errorDriver: Driver<String?> { get }
}

extension SolanaBuyToken {
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
            
            inputRelay
                .flatMap { [weak self] input -> Single<Buy.ExchangeOutput> in
                    guard let self = self else { return .error(NSError(domain: "SolanaBuyToken", code: -1)) }
                    return self.exchangeService
                        .convert(input: input, to: self.outputRelay.value.currency)
                        .catch { error in
                            self.errorRelay.accept(error.localizedDescription)
                            return .just(.init(amount: 0, currency: self.outputRelay.value.currency, processingFee: 0, networkFee: 0, total: 0))
                        }
                        .do { output in
                            self.errorRelay.accept(nil)
                        }
                }
                .bind(to: outputRelay)
                .disposed(by: disposeBag)
        }
        
        private let errorRelay = BehaviorRelay<String?>(value: nil)
        private let inputRelay = BehaviorRelay<Buy.ExchangeInput>(value: .init(amount: 0, currency: Buy.FiatCurrency.usd))
        private let outputRelay = BehaviorRelay<Buy.ExchangeOutput>(value: .init(amount: 0, currency: Buy.CryptoCurrency.sol, processingFee: 0, networkFee: 0, total: 0))
        private let exchangeRateRelay = BehaviorRelay<Buy.ExchangeRate?>(value: nil)
        
        func setAmount(value: Double?) {
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
            inputRelay.accept(input)
            outputRelay.accept(output)
        }
        
        var inputDriver: Driver<Buy.ExchangeInput> { inputRelay.asDriver() }
        
        var outputDriver: Driver<Buy.ExchangeOutput> { outputRelay.asDriver() }
        
        var exchangeRateDriver: Driver<Buy.ExchangeRate?> { exchangeRateRelay.asDriver() }
        
        var errorDriver: Driver<String?> { errorRelay.asDriver() }
        
        func next() { buyViewModel.navigate(to: .buyToken(crypto: .sol, amount: outputRelay.value.total)) }
        
        func back() { buyViewModel.navigate(to: .back) }
    }
}
