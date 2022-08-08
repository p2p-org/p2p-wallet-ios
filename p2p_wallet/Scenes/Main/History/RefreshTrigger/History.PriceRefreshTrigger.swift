//
// Created by Giang Long Tran on 19.04.2022.
//

import Combine
import Foundation
import Resolver

extension History {
    /// Updating price if exchange rate was change
    class PriceRefreshTrigger: HistoryRefreshTrigger {
        @Injected private var pricesService: PricesServiceType

        func register() -> AnyPublisher<Void, Never> {
            pricesService.currentPricesPublisher
                .receive(on: RunLoop.main)
                .map { _ in () }
                .replaceError(with: ())
                .eraseToAnyPublisher()
        }
    }
}
