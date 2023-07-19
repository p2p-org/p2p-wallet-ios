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
import TransactionParser

protocol TransactionHandlerType {
    typealias TransactionIndex = Int
    func sendTransaction(_ processingTransaction: RawTransactionType) -> TransactionIndex
    func observeTransaction(transactionIndex: TransactionIndex) -> AnyPublisher<PendingTransaction?, Never>

    func observePendingTransactions() -> AnyPublisher<[PendingTransaction], Never>
}

class TransactionHandler: TransactionHandlerType {
    // MARK: - Dependencies

    @Injected var notificationsService: NotificationService
    @Injected var apiClient: SolanaAPIClient

    // MARK: - Properties

    let transactionsSubject = CurrentValueSubject<[PendingTransaction], Never>([])
    let onNewTransactionSubject = PassthroughSubject<(trx: PendingTransaction, index: Int), Never>()

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

    func observePendingTransactions() -> AnyPublisher<[PendingTransaction], Never> {
        transactionsSubject
            .eraseToAnyPublisher()
    }
}
