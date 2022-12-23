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
import Sell

extension History {
    /// Updating price if exchange rate was change
    class SellTransactionsRefreshTrigger: HistoryRefreshTrigger {
        // MARK: - Dependencies
        @Injected private var sellDataService: any SellDataService

        func register() -> Signal<Void> {
            sellDataService
                .transactionsPublisher
                .asObservable()
                .map { _ in () }
                .asSignal(onErrorJustReturn: ())
        }
    }
}
