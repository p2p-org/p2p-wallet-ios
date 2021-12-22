//
//  TransactionsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import RxSwift
import RxCocoa

class TransactionsViewModel: BEListViewModel<SolanaSDK.ParsedTransaction> {
    // MARK: - Dependencies
    private let account: String
    private let accountSymbol: String
    private var before: String?
    private let repository: TransactionsRepository
    private let pricesService: PricesServiceType
    private let processingTransactionRepository: ProcessingTransactionsRepository
    private let feeRelayer: FeeRelayerType
    private let notificationsRepository: WLNotificationsRepository
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var fetchedFeePayer = false
    private let isFetchingReceiptSubject = BehaviorRelay<Bool>(value: false)
    var isFetchingReceiptDriver: Driver<Bool> {
        isFetchingReceiptSubject.asDriver()
    }
    
    // MARK: - Subjects
    init(
        account: String,
        accountSymbol: String,
        repository: TransactionsRepository,
        pricesService: PricesServiceType,
        processingTransactionRepository: ProcessingTransactionsRepository,
        feeRelayer: FeeRelayerType,
        notificationsRepository: WLNotificationsRepository
    ) {
        self.account = account
        self.accountSymbol = accountSymbol
        self.repository = repository
        self.pricesService = pricesService
        self.processingTransactionRepository = processingTransactionRepository
        self.feeRelayer = feeRelayer
        self.notificationsRepository = notificationsRepository
        super.init(isPaginationEnabled: true, limit: 10)
    }
    
    override func bind() {
        super.bind()
        pricesService.currentPricesDriver
            .drive(onNext: {[weak self] _ in
                self?.refreshUI()
            })
            .disposed(by: disposeBag)
        
        processingTransactionRepository.processingTransactionsObservable()
            .subscribe(onNext: {[weak self] _ in
                self?.refreshUI()
            })
            .disposed(by: disposeBag)
        
        notificationsRepository.observeChange(account: account)
            .distinctUntilChanged()
            .do(onNext: {[weak self] _ in
                self?.isFetchingReceiptSubject.accept(true)
            })
            .delay(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] notification in
                switch notification {
                case .received:
                    self?.getNewReceipt()
                case .sent:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func createRequest() -> Single<[SolanaSDK.ParsedTransaction]> {
        let fetchPubkeys: Single<[String]>
        if fetchedFeePayer {
            fetchPubkeys = .just(Defaults.p2pFeePayerPubkeys)
        } else {
            fetchPubkeys = feeRelayer.getFeePayerPubkey()
                .catchAndReturn("")
                .flatMap {newFeePayer in
                    if !newFeePayer.isEmpty, !Defaults.p2pFeePayerPubkeys.contains(newFeePayer)
                    {
                        Defaults.p2pFeePayerPubkeys.append(newFeePayer)
                    }
                    return .just(Defaults.p2pFeePayerPubkeys)
                }
        }
        
        return fetchPubkeys
            .flatMap { [weak self] pubkeys -> Single<[SolanaSDK.ParsedTransaction]> in
                guard let `self` = self else {return .error(SolanaSDK.Error.unknown)}
                return self.repository.getTransactionsHistory(
                    account: self.account,
                    accountSymbol: self.accountSymbol,
                    before: self.before,
                    limit: self.limit,
                    p2pFeePayerPubkeys: pubkeys
                )
            }
            .do(
                afterSuccess: {[weak self] transactions in
                    self?.before = transactions.last?.signature
                }
            )
    }
    
    override func map(newData: [SolanaSDK.ParsedTransaction]) -> [SolanaSDK.ParsedTransaction] {
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
            .map { [weak self] transactions -> [SolanaSDK.ParsedTransaction] in
                // find receipt
                let newTransactions = transactions.filter {newTx in self?.data.contains(where: {$0.signature == newTx.signature}) == false}
                
                // receive
                if newTransactions.contains(where: {($0.value as? SolanaSDK.TransferTransaction)?.transferType == .receive})
                {
                    return newTransactions
                }
                
                // throw
                throw SolanaSDK.Error.notFound
            }
            .retry(maxAttempts: 3, delayInSeconds: 2)
            .subscribe(onSuccess: {[weak self] newTransactions in
                guard let self = self else {return}
                self.isFetchingReceiptSubject.accept(false)
                let newTransactions = newTransactions.filter {newTx in !self.data.contains(where: {$0.signature == newTx.signature})}
                var data = self.data
                data = newTransactions + data
                self.overrideData(by: data)
            }, onFailure: {[weak self] _ in
                self?.isFetchingReceiptSubject.accept(false)
//                self.notificationsService.showToast(message: L10n.errorRetrievingReceipt + ": " + error.readableDescription + ". " + L10n.pleaseTryAgainLater.uppercaseFirst)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func updatedTransactionsWithPrices(transactions: [SolanaSDK.ParsedTransaction]) -> [SolanaSDK.ParsedTransaction]
    {
        var transactions = transactions
        for index in 0..<transactions.count {
            transactions[index] = updatedTransactionWithPrice(transaction: transactions[index])
        }
        return transactions
    }
    
    private func updatedTransactionWithPrice(
        transaction: SolanaSDK.ParsedTransaction
    ) -> SolanaSDK.ParsedTransaction {
        guard let price = pricesService.currentPrice(for: transaction.symbol)
        else {return transaction}
        
        var transaction = transaction
        let amount = transaction.amount
        transaction.amountInFiat = amount * price.value
        
        return transaction
    }
    
    private func insertProcessingTransaction(
        intoCurrentData currentData: [SolanaSDK.ParsedTransaction]
    ) -> [SolanaSDK.ParsedTransaction] {
        let processingTransactions = processingTransactionRepository.getProcessingTransactions()
        var transactions = [SolanaSDK.ParsedTransaction]()
        for var pt in processingTransactions {
            switch pt.value {
            case let transaction as SolanaSDK.TransferTransaction:
                if transaction.source?.pubkey == self.account ||
                    transaction.destination?.pubkey == self.account ||
                    transaction.authority == self.account
                {
                    transactions.append(pt)
                }
            case _ as SolanaSDK.CloseAccountTransaction:
                // FIXME: - Close account
                break
            case var transaction as SolanaSDK.SwapTransaction:
                if transaction.source?.pubkey == self.account ||
                    transaction.destination?.pubkey == self.account
                {
                    transaction.myAccountSymbol = accountSymbol
                    pt.value = transaction
                    transactions.append(pt)
                }
            default:
                break
            }
        }
        
        transactions = transactions.filter {!$0.isFailure}
            .sorted(by: {$0.blockTime?.timeIntervalSince1970 > $1.blockTime?.timeIntervalSince1970})
        
        var data = currentData
        for transaction in transactions.reversed()
        {
            // update if exists and is being processed
            if let index = data.firstIndex(where: {$0.signature == transaction.signature})
            {
                if data[index].status != .confirmed {
                    data[index] = transaction
                }
            }
            // append if not
            else {
                if transaction.signature != nil {
                    data.removeAll(where: {$0.signature == nil})
                }
                data.insert(transaction, at: 0)
            }
            
        }
        return data
    }
}
