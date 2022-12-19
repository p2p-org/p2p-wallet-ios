//
//  History.SellTransactionRefreshTrigger.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/12/2022.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift

extension History {
    /// Updating price if exchange rate was change
    class SellTransactionsRefreshTrigger: HistoryRefreshTrigger {
        @Injected private var pricesService: PricesServiceType

        func register() -> Signal<Void> {
            fatalError()
        }
    }
}
