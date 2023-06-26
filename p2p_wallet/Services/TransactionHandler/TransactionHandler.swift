//
//  TransactionHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2022.
//

import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift

protocol TransactionHandlerType {
    typealias TransactionIndex = Int
    func sendTransaction(_ processingTransaction: RawTransactionType) -> TransactionIndex
    func observeTransaction(transactionIndex: TransactionIndex) -> AnyPublisher<PendingTransaction?, Never>
    func areSomeTransactionsInProgress() -> Bool

    func observePendingTransactions() -> AnyPublisher<[PendingTransaction], Never>
    func getProcessingTransaction(index: Int) -> PendingTransaction

    var onNewTransaction: AnyPublisher<(trx: PendingTransaction, index: Int), Never> { get }
}

class TransactionHandler: TransactionHandlerType {
    // MARK: - Dependencies

    @Injected var notificationsService: NotificationService
    @Injected var analyticsManager: AnalyticsManager
    @Injected var apiClient: SolanaAPIClient
    @Injected var walletsRepository: WalletsRepository
    @Injected var pricesService: PricesServiceType
    @Injected var errorObserver: ErrorObserver

    // MARK: - Properties

    var subscriptions = Set<AnyCancellable>()
    let transactionsSubject = CurrentValueSubject<[PendingTransaction], Never>([])
    let onNewTransactionSubject = PassthroughSubject<(trx: PendingTransaction, index: Int), Never>()
    var onNewTransaction: AnyPublisher<(trx: PendingTransaction, index: Int), Never> { onNewTransactionSubject.eraseToAnyPublisher()
    }

    func sendTransaction(
        _ processingTransaction: RawTransactionType
    ) -> TransactionIndex {
        // get index to return
        let txIndex = transactionsSubject.value.count

        // add to processing
        let trx = PendingTransaction(
            trxIndex: txIndex,
            transactionId: nil,
            sentAt: Date(),
            rawTransaction: processingTransaction,
            status: .sending
        )

        var value = transactionsSubject.value
        value.append(trx)

        transactionsSubject.send(value)
        onNewTransactionSubject.send((trx, txIndex))

        // process
        sendAndObserve(index: txIndex, processingTransaction: processingTransaction)

        return txIndex
    }

    func observeTransaction(
        transactionIndex: TransactionIndex
    ) -> AnyPublisher<PendingTransaction?, Never> {
        transactionsSubject.map { $0[safe: transactionIndex] }.eraseToAnyPublisher()
    }

    func areSomeTransactionsInProgress() -> Bool {
        transactionsSubject.value.contains(where: \.status.isProcessing)
    }

    func observePendingTransactions() -> AnyPublisher<[PendingTransaction], Never> {
        transactionsSubject
            .eraseToAnyPublisher()
    }

    func getProcessingTransaction(index: Int) -> PendingTransaction {
        transactionsSubject.value[index]
    }
}
