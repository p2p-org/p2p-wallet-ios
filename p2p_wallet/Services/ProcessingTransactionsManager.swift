//
//  TransactionsManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/12/2020.
//

import Foundation
import RxSwift
import RxCocoa

class ProcessingTransactionsManager: ProcessingTransactionsRepository {
    // MARK: - Dependencies
    private let handler: TransactionHandler
    private let walletsRepository: WalletsRepository
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let transactionsSubject = BehaviorRelay<[SolanaSDK.ParsedTransaction]>(value: [])
    
    // MARK: - Initializer
    init(handler: TransactionHandler, walletsRepository: WalletsRepository) {
        self.handler = handler
        self.walletsRepository = walletsRepository
    }
    
    // MARK: - Methods
    func getProcessingTransactions() -> [SolanaSDK.ParsedTransaction] {
        transactionsSubject.value
    }
    
    func processingTransactionsObservable() -> Observable<[SolanaSDK.ParsedTransaction]> {
        transactionsSubject.asObservable()
    }
    
    func request(_ request: Single<ProcessTransactionResponseType>, transaction: SolanaSDK.ParsedTransaction, fee: SolanaSDK.Lamports) -> Int {
        // add pending transaction
        var transactions = transactionsSubject.value
        let index = transactions.count
        transactions.append(transaction)
        transactionsSubject.accept(transactions)
        
        // request
        request
            // update wallets repository
            .do(onSuccess: {[weak self] res in
                DispatchQueue.main.async { [weak self] in
                    self?.handleResponse(res, transactionIndex: index, fee: fee)
                }
            })
            // get signature
            .map { response -> String in
                if let swapResponse = response as? SolanaSDK.SwapResponse {
                    return swapResponse.transactionId
                }
                
                if let response = response as? SolanaSDK.TransactionID {
                    return response
                }
                
                throw SolanaSDK.Error.unknown
            }
            // update transaction status
            .do(onSuccess: {[weak self] signature in
                DispatchQueue.main.async { [weak self] in
                    self?.batchUpdateTransaction(transactionIndex: index, modifier: { transaction in
                        var transaction = transaction
                        transaction.status = .processing(percent: 0)
                        transaction.signature = signature
                        return transaction
                    })
                }
            })
            // signature subscribe
            .flatMapCompletable{ signature in
                self.handler.observeTransactionCompletion(signature: signature)
                    .timeout(.seconds(60), scheduler: MainScheduler.instance)
                    .catch {_ in .empty()}
            }
            .observe(on: MainScheduler.instance)
            // transactionConfirmed
            .subscribe(onCompleted: { [weak self] in
                self?.updateTransactionStatus(transactionIndex: index, status: .confirmed)
            }, onError: {[weak self] error in
                self?.updateTransactionStatus(transactionIndex: index, status: .error(error.readableDescription))
            })
            .disposed(by: disposeBag)
        
        return index
    }
    
    private func updateTransactionStatus(transactionIndex: Int, status: SolanaSDK.ParsedTransaction.Status)
    {
        if var transaction = transactionsSubject.value[safe: transactionIndex] {
            transaction.status = status
            var transactions = transactionsSubject.value
            transactions[transactionIndex] = transaction
            transactionsSubject.accept(transactions)
        }
    }
    
    private func batchUpdateTransaction(transactionIndex: Int, modifier: (SolanaSDK.ParsedTransaction) -> SolanaSDK.ParsedTransaction
    ) {
        if var transaction = transactionsSubject.value[safe: transactionIndex] {
            transaction = modifier(transaction)
            var transactions = transactionsSubject.value
            transactions[transactionIndex] = transaction
            transactionsSubject.accept(transactions)
        }
    }
    
    private func handleResponse(_ res: ProcessTransactionResponseType, transactionIndex: Int, fee: SolanaSDK.Lamports) {
        guard let tx = transactionsSubject.value[safe: transactionIndex],
              let transaction = tx.value
        else {
            return
        }
        
        // Send
        if let transaction = transaction as? SolanaSDK.TransferTransaction {
            walletsRepository.batchUpdate(closure: {
                var wallets = $0
                // update fromWallet
                if let fromWallet = transaction.source,
                   let amount = transaction.amount,
                    let index = wallets.firstIndex(where: {$0.pubkey == fromWallet.pubkey})
                {
                    wallets[index].decreaseBalance(diffInLamports: amount.toLamport(decimals: fromWallet.token.decimals))
                }
                
                // update toWallet (if send to different wallet of THIS account)
                if let toWallet = transaction.destination,
                   let amount = transaction.amount,
                    let index = wallets.firstIndex(where: {$0.pubkey == toWallet.pubkey})
                {
                    wallets[index].increaseBalance(diffInLamports: amount.toLamport(decimals: toWallet.token.decimals))
                }
                
                // update SOL wallet (minus fee)
                if let index = wallets.firstIndex(where: {$0.token.isNative})
                {
                    wallets[index].decreaseBalance(diffInLamports: fee)
                }
                return wallets
            })
        }
        
        // Close account
        else if let transaction = transaction as? SolanaSDK.CloseAccountTransaction {
            walletsRepository.batchUpdate(closure: {
                var wallets = $0
                var convertedAmount = transaction.reimbursedAmount ?? 0
                
                if let wallet = transaction.closedWallet {
                    // remove closed wallet
                    wallets.removeAll(where: {$0.pubkey == wallet.pubkey})
                    
                    // if closing non-native Solana wallet, then convert its balances and send it to native Solana wallet
                    if wallet.token.symbol == "SOL" {
                        convertedAmount += wallet.amount ?? 0
                    }
                }

                // update native solana wallet
                if let index = wallets.firstIndex(where: {$0.token.isNative})
                {
                    wallets[index].updateBalance(diff: convertedAmount)
                }

                return wallets
            })
        }
        
        // Swap
        else if let transaction = transaction as? SolanaSDK.SwapTransaction,
                let response = res as? SolanaSDK.SwapResponse
        {
            walletsRepository.batchUpdate(closure: {
                var wallets = $0

                // update source wallet
                if let sourceWallet = transaction.source,
                   let index = wallets.firstIndex(where: {$0.pubkey == sourceWallet.pubkey}),
                   let change = transaction.sourceAmount?.toLamport(decimals: sourceWallet.token.decimals)
                {
                    wallets[index].decreaseBalance(diffInLamports: change)
                }

                // update destination wallet if exists
                if let destinationWallet = transaction.destination,
                   let index = wallets.firstIndex(where: {$0.pubkey == destinationWallet.pubkey}),
                   let change = transaction.destinationAmount?.toLamport(decimals: destinationWallet.token.decimals)
                {
                    wallets[index].increaseBalance(diffInLamports: change)
                }

                // add new wallet if destination is a new wallet
                else if let pubkey = response.newWalletPubkey,
                        var wallet = transaction.destination,
                        let estimatedAmount = transaction.destinationAmount?.toLamport(decimals: wallet.token.decimals)
                {
                    wallet.pubkey = pubkey
                    wallet.lamports = estimatedAmount
                    wallets.append(wallet)
                }

                // update sol wallet (minus fee)
                if let index = wallets.firstIndex(where: {$0.token.isNative})
                {
                    wallets[index].decreaseBalance(diffInLamports: fee)
                }

                return wallets
            })
        }
    }
}
