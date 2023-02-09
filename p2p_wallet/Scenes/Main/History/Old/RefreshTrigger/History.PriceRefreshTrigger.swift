//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift
import RxCombine

extension History {
    /// Updating price if exchange rate was change
    class PriceRefreshTrigger: HistoryRefreshTrigger {
        @Injected private var pricesService: PricesServiceType

        func register() -> Signal<Void> {
            pricesService
                .currentPricesPublisher
                .asObservable()
                .flatMap { _ in Observable<Void>.just(()) }
                .asSignal(onErrorJustReturn: ())
        }
    }
}
