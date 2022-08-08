//
// Created by Giang Long Tran on 19.04.2022.
//

import Combine
import Foundation
import Resolver
import RxCombine

extension History {
    /// Refreshing history if processing transaction appears.
    ///
    /// This class have to be use with `ProcessingTransactionsOutput`
    class ProcessingTransactionRefreshTrigger: HistoryRefreshTrigger {
        @Injected private var repository: TransactionHandlerType

        func register() -> AnyPublisher<Void, Never> {
            repository
                .observeProcessingTransactions()
                .publisher
                .map { _ in () }
                .replaceError(with: ())
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
}
