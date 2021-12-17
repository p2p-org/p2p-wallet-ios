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
    func setAmount(value: Double)
    func back()
    func next()
    
    var quoteAmount: Driver<Double> { get }
    var solanaPrice: Driver<Double> { get }
    var feeAmount: Driver<Double> { get }
    var networkFee: Driver<Double> { get }
    var total: Driver<Double> { get }
}

extension SolanaBuyToken {
    class SceneModel: SolanaBuyTokenSceneModel {
        private let navigationSubject = PublishSubject<NavigatableScene>()
        @Injected private var moonpayService: MoonpayService
        
        let rootViewModel: BuyViewModelType
        let disposeBag = DisposeBag()
        
        init(rootViewModel: BuyViewModelType) {
            self.rootViewModel = rootViewModel
            
            moonpayService.getPrice(for: "eth", as: .usd)
                .catchError { error in
                    print(error)
                    return .just(0)
                }
                .asObservable()
                .bind(to: exchangePrice)
                .disposed(by: disposeBag)
        }
        
        private let input = BehaviorSubject<Double>(value: 0)
        private var quote: Observable<Moonpay.BuyQuote> {
            input.flatMapLatest { [weak self]  value -> Single<Moonpay.BuyQuote> in
                guard let self = self else { return .just(Moonpay.BuyQuote.empty()) }
                if value == 0 { return .just(Moonpay.BuyQuote.empty()) }
                return self.moonpayService.getBuyQuote(
                        baseCurrencyCode: "usd",
                        quoteCurrencyCode: "eth",
                        baseCurrencyAmount: value)
                    .catchError { error in
                        print(error)
                        return .just(Moonpay.BuyQuote.empty())
                    }
            }
        }
        
        private let exchangePrice = BehaviorSubject<Double>(value: 0)
        
        func setAmount(value: Double) { input.onNext(value) }
        
        func next() { rootViewModel.navigate(to: .buyToken(crypto: .eth, amount: (try? input.value()) ?? 0)) }
        
        func back() { rootViewModel.navigate(to: .back) }
        
        var quoteAmount: Driver<Double> { quote.map { $0.quoteCurrencyAmount }.asDriver(onErrorJustReturn: 0) }
        var feeAmount: Driver<Double> { quote.map { $0.feeAmount }.asDriver(onErrorJustReturn: 0) }
        var networkFee: Driver<Double> { quote.map { $0.networkFeeAmount }.asDriver(onErrorJustReturn: 0) }
        var total: Driver<Double> { quote.map { $0.totalAmount }.asDriver(onErrorJustReturn: 0) }
        var solanaPrice: Driver<Double> { exchangePrice.asDriver(onErrorJustReturn: 0) }
    }
}
