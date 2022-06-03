//
//  TransactionsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import BECollectionView
import FeeRelayerSwift
import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import TransactionParser

class TransactionsViewModel: BEListViewModel<ParsedTransaction> {
    // MARK: - Dependencies

    private let account: String
    private let accountSymbol: String
    private var before: String?
    @Injected private var repository: TransactionsRepository
    @Injected private var pricesService: PricesServiceType
    @Injected private var transactionHandler: TransactionHandlerType
    @Injected private var feeRelayer: FeeRelayerSwift.APIClient
    @Injected private var notificationsRepository: WLNotificationsRepository
    private var source: HistoryStreamSource = History.EmptyStreamSource()

    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var fetchedFeePayer = false
    private let isFetchingReceiptSubject = BehaviorRelay<Bool>(value: false)

    // MARK: - Subjects

    init(
        account: String,
        accountSymbol: String
    ) {
        self.account = account
        self.accountSymbol = accountSymbol
        super.init(isPaginationEnabled: true, limit: 10)
        buildSource()
    }

    override func bind() {
        super.bind()
        pricesService.currentPricesDriver
            .drive(onNext: { [weak self] _ in
                self?.refreshUI()
            })
            .disposed(by: disposeBag)

        transactionHandler.observeProcessingTransactions(forAccount: account)
            .subscribe(onNext: { [weak self] _ in
                self?.refreshUI()
            })
            .disposed(by: disposeBag)

        notificationsRepository.observeChange(account: account)
            .distinctUntilChanged()
            .do(onNext: { [weak self] _ in
                self?.isFetchingReceiptSubject.accept(true)
            })
            .delay(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                switch notification {
                case .received:
                    self?.getNewReceipt()
                case .sent:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    override func createRequest() -> Single<[ParsedTransaction]> {
//        next().asSingle()

        fatalError("Method has not been implemented")

        // let fetchPubkeys: Single<[String]>
        // if fetchedFeePayer {
        //     fetchPubkeys = .just(Defaults.p2pFeePayerPubkeys)
        // } else {
        //     fetchPubkeys = feeRelayer.getFeePayerPubkey()
        //         .catchAndReturn("")
        //         .flatMap { newFeePayer in
        //             if !newFeePayer.isEmpty, !Defaults.p2pFeePayerPubkeys.contains(newFeePayer) {
        //                 Defaults.p2pFeePayerPubkeys.append(newFeePayer)
        //             }
        //             return .just(Defaults.p2pFeePayerPubkeys)
        //         }
        // }
        //
        // return fetchPubkeys
        //     .flatMap { [weak self] pubkeys -> Single<[ParsedTransaction]> in
        //         guard let self = self else { return .error(Error.unknown) }
        //         return self.repository.getTransactionsHistory(
        //             account: self.account,
        //             accountSymbol: self.accountSymbol,
        //             before: self.before,
        //             limit: self.limit,
        //             p2pFeePayerPubkeys: pubkeys
        //         )
        //     }
        //     .do(
        //         afterSuccess: { [weak self] transactions in
        //             self?.before = transactions.last?.signature
        //         }
        //     )
    }

//    func next() -> Observable<[ParsedTransaction]> {
//        AsyncThrowingStream<[HistoryStreamSource.Result], Error> { stream in
//            Task {
//                defer { stream.finish(throwing: nil) }
//
//                var results: [HistoryStreamSource.Result] = []
//                do {
//                    while true {
//                        let firstTrx = try await source.first()
//                        guard
//                            let firstTrx = firstTrx,
//                            let rawTime = firstTrx.0.blockTime
//                        else {
//                            stream.yield(results)
//                            return
//                        }
//
//                        // Fetch next 1 days
//                        var timeEndFilter = Date(timeIntervalSince1970: TimeInterval(rawTime))
//                        timeEndFilter = timeEndFilter.addingTimeInterval(-1 * 60 * 60 * 24 * 1)
//
//                        if Task.isCancelled { return }
//                        for try await result in source.next(
//                            configuration: .init(timestampEnd: timeEndFilter)
//                        ) {
//                            if Task.isCancelled { return }
//
//                            let (signatureInfo, _, _) = result
//
//                            // Skip duplicated transaction
//                            if data.contains(where: { $0.signature == signatureInfo.signature }) { continue }
//                            if results
//                                .contains(where: { $0.0.signature == signatureInfo.signature }) { continue }
//
//                            results.append(result)
//
//                            if results.count > 15 {
//                                stream.yield(results)
//                                return
//                            }
//                        }
//                    }
//                } catch {
//                    stream.yield(results)
//                    stream.finish(throwing: error)
//                }
//            }
//        }
//        .asObservable()
//        .flatMap { results in Observable.from(results) }
//        .flatMap { result in
//            // TODO: FIX
//            Single.async { () -> [ParsedTransaction] in
//                print(Date())
//                let transactionInfo = try await self.transactionRepository
//                    .getTransaction(signature: result.0.signature)
//                let transaction = try await self.transactionParser.parse(
//                    signatureInfo: result.0,
//                    transactionInfo: transactionInfo,
//                    account: result.1,
//                    symbol: result.2
//                )
//
//                return [transaction]
//            }
//        }
//        .do(onError: { [weak self] error in
//            DispatchQueue.main.async { [weak self] in
//                self?.errorRelay.accept(true)
//                self?.notificationService.showInAppNotification(.error(error))
//            }
//        })
//    }

    func buildSource() {
        let cachedTransactionRepository: History.CachingTransactionRepository = .init(
            delegate: History.SolanaTransactionRepository()
        )
        let cachedTransactionParser = History.DefaultTransactionParser(p2pFeePayers: Defaults.p2pFeePayerPubkeys)
        let accountStreamSource = History.AccountStreamSource(
            account: account,
            symbol: accountSymbol,
            transactionRepository: cachedTransactionRepository,
            transactionParser: cachedTransactionParser
        )

        source = History.MultipleStreamSource(sources: [accountStreamSource])
    }

    override func map(newData: [ParsedTransaction]) -> [ParsedTransaction] {
        var transactions = insertProcessingTransaction(intoCurrentData: newData)
        transactions = updatedTransactionsWithPrices(transactions: transactions)
        return transactions
    }

    override func flush() {
        before = nil
        super.flush()
    }

    /// get most recent receiving transaction if posible
    private func getNewReceipt() {
        repository.getTransactionsHistory(
            account: account,
            accountSymbol: accountSymbol,
            before: nil,
            limit: 3,
            p2pFeePayerPubkeys: Defaults.p2pFeePayerPubkeys
        )
            .map { [weak self] transactions -> [ParsedTransaction] in
                // find receipt
                let newTransactions = transactions
                    .filter { newTx in self?.data.contains(where: { $0.signature == newTx.signature }) == false }

                // receive
                if newTransactions
                    .contains(where: { ($0.value as? TransferTransaction)?.transferType == .receive })
                {
                    return newTransactions
                }

                // throw
                throw SolanaError.notFound
            }
            .retry(maxAttempts: 3, delayInSeconds: 2)
            .subscribe(onSuccess: { [weak self] newTransactions in
                guard let self = self else { return }
                self.isFetchingReceiptSubject.accept(false)
                let newTransactions = newTransactions
                    .filter { newTx in !self.data.contains(where: { $0.signature == newTx.signature }) }
                var data = self.data
                data = newTransactions + data
                self.overrideData(by: data)
            }, onFailure: { [weak self] _ in
                self?.isFetchingReceiptSubject.accept(false)
//                self.notificationsService.showToast(message: L10n.errorRetrievingReceipt + ": " + error.readableDescription + ". " + L10n.pleaseTryAgainLater.uppercaseFirst)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers

    private func updatedTransactionsWithPrices(transactions: [ParsedTransaction])
        -> [ParsedTransaction]
    {
        var transactions = transactions
        for index in 0 ..< transactions.count {
            transactions[index] = updatedTransactionWithPrice(transaction: transactions[index])
        }
        return transactions
    }

    private func updatedTransactionWithPrice(
        transaction: ParsedTransaction
    ) -> ParsedTransaction {
        guard let price = pricesService.currentPrice(for: transaction.symbol)
        else { return transaction }

        var transaction = transaction
        let amount = transaction.amount
        transaction.amountInFiat = amount * price.value

        return transaction
    }

    private func insertProcessingTransaction(
        intoCurrentData currentData: [ParsedTransaction]
    ) -> [ParsedTransaction] {
        let transactions = transactionHandler.getProccessingTransactions(of: account)
            .filter { !$0.isFailure }
            .sorted(by: { $0.blockTime?.timeIntervalSince1970 > $1.blockTime?.timeIntervalSince1970 })

        var data = currentData
        for transaction in transactions.reversed() {
            // update if exists and is being processed
            if let index = data.firstIndex(where: { $0.signature == transaction.signature }) {
                if data[index].status != .confirmed {
                    data[index] = transaction
                }
            }
            // append if not
            else {
                if transaction.signature != nil {
                    data.removeAll(where: { $0.signature == nil })
                }
                data.insert(transaction, at: 0)
            }
        }
        return data
    }
}
