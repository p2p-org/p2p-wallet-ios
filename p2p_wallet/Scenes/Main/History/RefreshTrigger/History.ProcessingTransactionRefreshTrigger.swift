//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation
import RxCocoa
import RxSwift

extension History {
    /// Refreshing history if processing transaction appears.
    ///
    /// This class have to be use with `ProcessingTransactionsOutput`
    class ProcessingTransactionRefreshTrigger: HistoryRefreshTrigger {
        @Injected private var repository: TransactionHandlerType

        func register() -> Signal<Void> {
            repository
                .observeProcessingTransactions()
                .flatMap { _ in Observable<Void>.just(()) }
                .asSignal(onErrorJustReturn: ())
        }
    }
}
