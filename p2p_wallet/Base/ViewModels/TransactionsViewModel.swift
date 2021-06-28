//
//  TransactionsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import RxSwift

class TransactionsViewModel: BEListViewModel<SolanaSDK.AnyTransaction> {
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
        
//        processingTransactionRepository.processingTransactionsObservable()
//            .filter {processingTransactions in
//                var transactions = [ProcessingTransaction]()
//                for pt in processingTransactions where pt.transaction != nil {
//
//                }
//            }
    }
    
    override func createRequest() -> Single<[SolanaSDK.AnyTransaction]> {
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
            .do(
                afterSuccess: {[weak self] transactions in
                    self?.before = transactions.last?.signature
                }
            )
    }
    
    override func map(newData: [SolanaSDK.AnyTransaction]) -> [SolanaSDK.AnyTransaction] {
        updatedTransactionsWithPrices(transactions: newData)
    }
    
    override func flush() {
        before = nil
        super.flush()
    }
    
    // MARK: - Helpers
    private func updatedTransactionsWithPrices(transactions: [SolanaSDK.AnyTransaction]) -> [SolanaSDK.AnyTransaction]
    {
        var transactions = transactions
        for index in 0..<transactions.count {
            transactions[index] = updatedTransactionWithPrice(transaction: transactions[index])
        }
        return transactions
    }
    
    private func updatedTransactionWithPrice(
        transaction: SolanaSDK.AnyTransaction
    ) -> SolanaSDK.AnyTransaction {
        guard let price = pricesRepository.currentPrice(for: transaction.symbol)
        else {return transaction}
        
        var transaction = transaction
        transaction.amountInFiat = transaction.amount * price.value
        
        return transaction
    }
}
