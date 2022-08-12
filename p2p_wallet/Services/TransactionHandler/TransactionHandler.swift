//
//  TransactionHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift
import TransactionParser

protocol TransactionHandlerType {
    typealias TransactionIndex = Int
    func sendTransaction(_ processingTransaction: RawTransactionType) async throws -> TransactionIndex
    func observeTransaction(transactionIndex: TransactionIndex) -> AnyPublisher<PendingTransaction?, Never>
    func areSomeTransactionsInProgress() -> Bool

    func observeProcessingTransactions(forAccount account: String) -> AnyPublisher<[ParsedTransaction], Never>
    func observeProcessingTransactions() -> AnyPublisher<[ParsedTransaction], Never>

    func getProccessingTransactions(of account: String) -> [ParsedTransaction]
    func getProcessingTransaction() -> [ParsedTransaction]

    var onNewTransaction: AnyPublisher<(trx: PendingTransaction, index: Int), Never> { get }
}

class TransactionHandler: ObservableObject, TransactionHandlerType {
    @Injected var notificationsService: NotificationService
    @Injected var analyticsManager: AnalyticsManager
    @Injected var apiClient: SolanaAPIClient
    @Injected var walletsRepository: WalletsRepository
    @Injected var pricesService: PricesServiceType
    @Injected var socket: AccountObservableService

    private var subscriptions = [AnyCancellable]()
    @Published var transactions = [PendingTransaction]()
    let onNewTransactionPublish = PassthroughSubject<(trx: PendingTransaction, index: Int), Never>()
    var onNewTransaction: AnyPublisher<(trx: PendingTransaction, index: Int), Never> {
        onNewTransactionPublish.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    func sendTransaction(
        _ processingTransaction: RawTransactionType
    ) async throws -> TransactionIndex {
        // get index to return
        let txIndex = transactions.count

        // add to processing
        let trx = PendingTransaction(
            transactionId: nil,
            sentAt: Date(),
            rawTransaction: processingTransaction,
            status: .sending
        )

        var value = transactions
        value.append(trx)

        transactions = value
        onNewTransactionPublish.send((trx, txIndex))

        // process
        Task {
            try await sendAndObserve(index: txIndex, processingTransaction: processingTransaction)
        }

        return txIndex
    }

    func observeTransaction(
        transactionIndex: TransactionIndex
    ) -> AnyPublisher<PendingTransaction?, Never> {
        $transactions.map { $0[safe: transactionIndex] }
            .eraseToAnyPublisher()
    }

    func areSomeTransactionsInProgress() -> Bool {
        transactions.contains(where: \.status.isProcessing)
    }

    func observeProcessingTransactions(
        forAccount account: String
    ) -> AnyPublisher<[ParsedTransaction], Never> {
        $transactions
            .map { [weak self] _ in self?.getProccessingTransactions(of: account) ?? [] }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func observeProcessingTransactions() -> AnyPublisher<[ParsedTransaction], Never> {
        $transactions
            .map { [weak self] _ in self?.getProcessingTransaction() ?? [] }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func getProccessingTransactions(
        of account: String
    ) -> [ParsedTransaction] {
        transactions
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
        transactions
            .compactMap { pt -> ParsedTransaction? in
                pt.parse(pricesService: pricesService, authority: walletsRepository.nativeWallet?.pubkey)
            }
    }
}
