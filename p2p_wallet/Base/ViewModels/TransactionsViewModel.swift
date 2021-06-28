//
//  TransactionsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import RxSwift

class TransactionsViewModel: BEListViewModel<ParsedTransaction> {
    let account: String
    let accountSymbol: String
    var before: String?
    let repository: TransactionsRepository
    let pricesRepository: PricesRepository
    let processingTransactionRepository: ProcessingTransactionsRepository
    let disposeBag = DisposeBag()
    var fetchedFeePayer = false
    
    let feeRelayer: SolanaSDK.FeeRelayer
    
    init(
        account: String,
        accountSymbol: String,
        repository: TransactionsRepository,
        pricesRepository: PricesRepository,
        processingTransactionRepository: ProcessingTransactionsRepository,
        feeRelayerAPIClient: FeeRelayerSolanaAPIClient
    ) {
        self.account = account
        self.accountSymbol = accountSymbol
        self.repository = repository
        self.pricesRepository = pricesRepository
        self.processingTransactionRepository = processingTransactionRepository
        self.feeRelayer = SolanaSDK.FeeRelayer(solanaAPIClient: feeRelayerAPIClient)
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
            .subscribe(onNext: {[weak self] transactions in
                self?.refreshUI()
            })
            .disposed(by: disposeBag)
    }
    
    override func createRequest() -> Single<[ParsedTransaction]> {
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
            .flatMap { [weak self] pubkeys -> Single<[SolanaSDK.AnyTransaction]> in
                guard let `self` = self else {return .error(SolanaSDK.Error.unknown)}
                return self.repository.getTransactionsHistory(
                    account: self.account,
                    accountSymbol: self.accountSymbol,
                    before: self.before,
                    limit: self.limit,
                    p2pFeePayerPubkeys: pubkeys
                )
            }
            .map {
                $0.map {ParsedTransaction(status: .confirmed, parsed: $0)}
            }
            .do(
                afterSuccess: {[weak self] transactions in
                    self?.before = transactions.last?.parsed?.signature
                }
            )
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
    
    // MARK: - Helpers
    private func updatedTransactionsWithPrices(transactions: [ParsedTransaction]) -> [ParsedTransaction]
    {
        var transactions = transactions
        for index in 0..<transactions.count {
            transactions[index] = updatedTransactionWithPrice(transaction: transactions[index])
        }
        return transactions
    }
    
    private func updatedTransactionWithPrice(
        transaction: ParsedTransaction
    ) -> ParsedTransaction {
        guard let price = pricesRepository.currentPrice(for: transaction.parsed?.symbol ?? "")
        else {return transaction}
        
        var transaction = transaction
        let amount = transaction.parsed?.amount
        transaction.parsed?.amountInFiat = amount * price.value
        
        return transaction
    }
    
    private func insertProcessingTransaction(
        intoCurrentData currentData: [ParsedTransaction]
    ) -> [ParsedTransaction] {
        let processingTransactions = processingTransactionRepository.getProcessingTransactions()
        var transactions = [ParsedTransaction]()
        for pt in processingTransactions where pt.parsed != nil {
            switch pt.parsed?.value {
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
            case let transaction as SolanaSDK.SwapTransaction:
                if transaction.source?.pubkey == self.account ||
                    transaction.destination?.pubkey == self.account
                {
                    transactions.append(pt)
                }
            default:
                break
            }
        }
        
        transactions = transactions
            .sorted(by: {$0.parsed?.blockTime?.timeIntervalSince1970 > $1.parsed?.blockTime?.timeIntervalSince1970})
        
        var data = currentData
        for transaction in transactions.reversed()
        {
            // update if exists and is being processed
            if let index = data.firstIndex(where: {$0.parsed?.signature == transaction.parsed?.signature})
            {
                if data[index].status != .confirmed {
                    data[index] = transaction
                }
            }
            // append if not
            else {
                data.insert(transaction, at: 0)
            }
            
        }
        return data
    }
}
