//
//  TransactionsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import RxSwift

class TransactionsViewModel: BEListViewModel<SolanaSDK.ParsedTransaction> {
    let account: String
    let accountSymbol: String
    var before: String?
    let repository: TransactionsRepository
    let pricesRepository: PricesRepository
    let processingTransactionRepository: ProcessingTransactionsRepository
    let disposeBag = DisposeBag()
    var fetchedFeePayer = false
    
    let feeRelayer: SolanaSDK.FeeRelayer
    let accountNotificationsRepository: AccountNotificationsRepository
    
    init(
        account: String,
        accountSymbol: String,
        repository: TransactionsRepository,
        pricesRepository: PricesRepository,
        processingTransactionRepository: ProcessingTransactionsRepository,
        feeRelayerAPIClient: FeeRelayerSolanaAPIClient,
        accountNotificationsRepository: AccountNotificationsRepository
    ) {
        self.account = account
        self.accountSymbol = accountSymbol
        self.repository = repository
        self.pricesRepository = pricesRepository
        self.processingTransactionRepository = processingTransactionRepository
        self.feeRelayer = SolanaSDK.FeeRelayer(solanaAPIClient: feeRelayerAPIClient)
        self.accountNotificationsRepository = accountNotificationsRepository
        super.init(isPaginationEnabled: true, limit: 10)
    }
    
    override func bind() {
        super.bind()
        pricesRepository.pricesObservable()
            .subscribe(onNext: {[weak self] _ in
                self?.refreshUI()
            })
            .disposed(by: disposeBag)
        
        processingTransactionRepository.processingTransactionsObservable()
            .subscribe(onNext: {[weak self] _ in
                self?.refreshUI()
            })
            .disposed(by: disposeBag)
        
        accountNotificationsRepository.observeAccountNotifications(account: account)
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in
                self?.reload()
            })
            .disposed(by: disposeBag)
    }
    
    override func createRequest() -> Single<[SolanaSDK.ParsedTransaction]> {
        let fetchPubkeys: Single<[String]>
        if fetchedFeePayer {
            fetchPubkeys = .just(Defaults.p2pFeePayerPubkeys)
        } else {
            fetchPubkeys = feeRelayer.getFeePayerPubkey()
                .map {$0.base58EncodedString}
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
        guard let price = pricesRepository.currentPrice(for: transaction.symbol)
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
            case let transaction as SolanaSDK.CloseAccountTransaction:
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
        
        transactions = transactions
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
