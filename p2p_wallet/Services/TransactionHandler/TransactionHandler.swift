//
//  TransactionHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2022.
//

import AnalyticsManager
import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import TransactionParser

protocol TransactionHandlerType {
    typealias TransactionIndex = Int
    func sendTransaction(_ processingTransaction: RawTransactionType) -> TransactionIndex
    func observeTransaction(transactionIndex: TransactionIndex) -> Observable<PendingTransaction?>
    func areSomeTransactionsInProgress() -> Bool

    func observeProcessingTransactions(forAccount account: String) -> Observable<[ParsedTransaction]>
    func observeProcessingTransactions() -> Observable<[ParsedTransaction]>

    func getProccessingTransactions(of account: String) -> [ParsedTransaction]
    func getProcessingTransaction() -> [ParsedTransaction]

    var onNewTransaction: Observable<(trx: PendingTransaction, index: Int)> { get }
}

class TransactionHandler: TransactionHandlerType {
    @Injected var notificationsService: NotificationService
    @Injected var analyticsManager: AnalyticsManager
    @Injected var apiClient: SolanaAPIClient
    @Injected var walletsRepository: WalletsRepository
    @Injected var pricesService: PricesServiceType
    @Injected var socket: AccountObservableService

    let disposeBag = DisposeBag()
    let transactionsSubject = BehaviorRelay<[PendingTransaction]>(value: [])
    let onNewTransactionPublish = PublishRelay<(trx: PendingTransaction, index: Int)>()
    var onNewTransaction: Observable<(trx: PendingTransaction, index: Int)> { onNewTransactionPublish.asObservable() }

    func sendTransaction(
        _ processingTransaction: RawTransactionType
    ) -> TransactionIndex {
        // get index to return
        let txIndex = transactionsSubject.value.count

        // add to processing
        let trx = PendingTransaction(
            transactionId: nil,
            sentAt: Date(),
            rawTransaction: processingTransaction,
            status: .sending
        )

        var value = transactionsSubject.value
        value.append(trx)

        transactionsSubject.accept(value)
        onNewTransactionPublish.accept((trx, txIndex))

        // process
        sendAndObserve(index: txIndex, processingTransaction: processingTransaction)

        return txIndex
    }

    func observeTransaction(
        transactionIndex: TransactionIndex
    ) -> Observable<PendingTransaction?> {
        transactionsSubject.map { $0[safe: transactionIndex] }
    }

    func areSomeTransactionsInProgress() -> Bool {
        transactionsSubject.value.contains(where: \.status.isProcessing)
    }

    func observeProcessingTransactions(
        forAccount account: String
    ) -> Observable<[ParsedTransaction]> {
        transactionsSubject
            .map { [weak self] _ in self?.getProccessingTransactions(of: account) ?? [] }
            .asObservable()
    }

    func observeProcessingTransactions() -> Observable<[ParsedTransaction]> {
        transactionsSubject
            .map { [weak self] _ in self?.getProcessingTransaction() ?? [] }
            .asObservable()
    }

    func getProccessingTransactions(
        of account: String
    ) -> [ParsedTransaction] {
        transactionsSubject.value
            .filter { pt in
                switch pt.rawTransaction {
                case let transaction as ProcessTransaction.SendTransaction:
                    if transaction.sender.pubkey == account ||
                        transaction.receiver.address == account ||
                        transaction.authority == account
                    {
                        return true
                    }
                case let transaction as ProcessTransaction.SwapTransaction:
                    if transaction.sourceWallet.pubkey == account ||
                        transaction.destinationWallet.pubkey == account ||
                        transaction.authority == account
                    {
                        return true
                    }
                default:
                    break
                }
                return false
            }
            .compactMap { pt -> ParsedTransaction? in
                pt.parse(pricesService: pricesService, authority: walletsRepository.nativeWallet?.pubkey)
            }
    }

    func getProcessingTransaction() -> [ParsedTransaction] {
        transactionsSubject.value
            .compactMap { pt -> ParsedTransaction? in
                pt.parse(pricesService: pricesService, authority: walletsRepository.nativeWallet?.pubkey)
            }
    }
}
