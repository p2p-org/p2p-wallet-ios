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
    
    var quoteAmount: Driver<Double> { get }
    var feeAmount: Driver<Double> { get }
    var networkFee: Driver<Double> { get }
    var total: Driver<Double> { get }
}

extension SolanaBuyToken {
    class SceneModel: SolanaBuyTokenSceneModel {
        private let navigationSubject = PublishSubject<NavigatableScene>()
        @Injected private var moonpayService: MoonpayService
        
        init() {}
        
        private let input = BehaviorSubject<Double>(value: 0)
        private var quote: Observable<Moonpay.BuyQuote> {
            input.flatMapLatest { [weak self]  value -> Single<Moonpay.BuyQuote> in
                print(value)
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
        
        
        func setAmount(value: Double) { input.onNext(value) }
        
        var quoteAmount: Driver<Double> { quote.map { $0.quoteCurrencyAmount }.asDriver(onErrorJustReturn: 0) }
        var feeAmount: Driver<Double> { quote.map { $0.feeAmount }.asDriver(onErrorJustReturn: 0) }
        var networkFee: Driver<Double> { quote.map { $0.networkFeeAmount }.asDriver(onErrorJustReturn: 0) }
        var total: Driver<Double> { quote.map { $0.totalAmount }.asDriver(onErrorJustReturn: 0) }
    }
}

extension SolanaBuyToken.SceneModel: BESceneNavigationModel {
    var navigationDriver: Driver<NavigationType> {
        navigationSubject.map { [weak self] scene in
            guard let self = self else { return .none }
            switch scene {
            case .back:
                return .pop
            }
            return .none
        }.asDriver(onErrorJustReturn: .none)
    }
}
