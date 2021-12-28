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
    func back()
    func next()
    
    var quoteAmount: Driver<Double> { get }
    var solanaPrice: Driver<Double> { get }
    var feeAmount: Driver<Double> { get }
    var networkFee: Driver<Double> { get }
    var total: Driver<Double> { get }
    var nextStatus: Driver<SolanaBuyToken.NextStatus> { get }
}

extension SolanaBuyToken {
    struct NextStatus {
        let text: String
        let isEnable: Bool
    }
    
    class SceneModel: SolanaBuyTokenSceneModel {
        private let navigationSubject = PublishSubject<NavigatableScene>()
        @Injected private var moonpayService: MoonpayService
        @Injected private var rootViewModel: BuyViewModelType
        let disposeBag = DisposeBag()
        
        init() {
            moonpayService.getPrice(for: "eth", as: .usd)
                .catch { error in
                    print(error)
                    return .just(0)
                }
                .asObservable()
                .bind(to: exchangePrice)
                .disposed(by: disposeBag)
        }
        
        private let input = BehaviorRelay<Double?>(value: nil)
        private var state: Observable<State> {
            input.flatMap { [weak self] value -> Single<State> in
                guard let self = self,
                      let value = value else { return .just(.none) }
                return self.moonpayService.getBuyQuote(
                    baseCurrencyCode: "usd",
                    quoteCurrencyCode: "eth",
                    baseCurrencyAmount: value
                ).map { quote in
                    .result(quote: quote)
                }.catch { error in
                    if let error = error as? Moonpay.Error {
                        switch error {
                        case .default(let message): return .just(.error(message))
                        }
                    }
                    return .just(.error(error.localizedDescription))
                }
            }
        }
        
        private let exchangePrice = BehaviorSubject<Double>(value: 0)
        
        func setAmount(value: Double?) { input.accept(value) }
        
        func next() { rootViewModel.navigate(to: .buyToken(crypto: .eth, amount: input.value ?? 0)) }
        
        func back() { rootViewModel.navigate(to: .back) }
        
        var quoteAmount: Driver<Double> {
            state.map {
                switch $0 {
                case .result(let quote): return quote.quoteCurrencyAmount
                default: return 0
                }
            }.asDriver(onErrorJustReturn: 0)
        }
        
        var feeAmount: Driver<Double> { state.map { $0.asResult()?.feeAmount ?? 0 }.asDriver(onErrorJustReturn: 0) }
        var networkFee: Driver<Double> { state.map { $0.asResult()?.networkFeeAmount ?? 0 }.asDriver(onErrorJustReturn: 0) }
        var total: Driver<Double> { state.map { $0.asResult()?.totalAmount ?? 0 }.asDriver(onErrorJustReturn: 0) }
        var solanaPrice: Driver<Double> { exchangePrice.asDriver(onErrorJustReturn: 0) }
        
        var nextStatus: Driver<NextStatus> {
            state.map { state in
                switch state {
                case .result: return .init(text: L10n.continue, isEnable: true)
                case .error(let message): return .init(text: message, isEnable: false)
                default: return .init(text: L10n.continue, isEnable: false)
                }
            }.asDriver { error in
                .just(NextStatus(text: error.localizedDescription, isEnable: false))
            }
        }
    }
    
}
