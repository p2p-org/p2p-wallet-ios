//
//  TransactionHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2022.
//

import Foundation
import RxSwift
import RxCocoa

protocol TransactionHandlerType {
    typealias TransactionIndex = Int
    func sendTransaction(_ processingTransaction: RawTransactionType) -> TransactionIndex
    func observeTransaction(transactionIndex: TransactionIndex) -> Observable<PendingTransaction?>
    func areSomeTransactionsInProgress() -> Bool
    
    func observeProcessingTransactions(forAccount account: String) -> Observable<[SolanaSDK.ParsedTransaction]>
    func getProccessingTransactions(of account: String) -> [SolanaSDK.ParsedTransaction]
}

class TransactionHandler: TransactionHandlerType {
    @Injected var notificationsService: NotificationsServiceType
    @Injected var apiClient: ProcessTransactionAPIClient
    @Injected var walletsRepository: WalletsRepository
    @Injected var pricesService: PricesServiceType
    @Injected var socket: SocketType
    
    let disposeBag = DisposeBag()
    let transactionsSubject = BehaviorRelay<[PendingTransaction]>(value: [])
    
    func sendTransaction(
        _ processingTransaction: RawTransactionType
    ) -> TransactionIndex {
        // get index to return
        let txIndex = transactionsSubject.value.count
        
        // add to processing
        var value = transactionsSubject.value
        value.append(
            .init(transactionId: nil, sentAt: Date(), rawTransaction: processingTransaction, status: .sending)
        )
        transactionsSubject.accept(value)
        
        // process
        sendAndObserve(index: txIndex, processingTransaction: processingTransaction)
        
        return txIndex
    }
    
    func observeTransaction(
        transactionIndex: TransactionIndex
    ) -> Observable<PendingTransaction?> {
        transactionsSubject.map {$0[safe: transactionIndex]}
    }
    
    func areSomeTransactionsInProgress() -> Bool {
        transactionsSubject.value.contains(where: {$0.status.isProcessing})
    }
    
    func observeProcessingTransactions(
        forAccount account: String
    ) -> Observable<[SolanaSDK.ParsedTransaction]> {
        transactionsSubject
            .map {[weak self] _ in self?.getProccessingTransactions(of: account) ?? []}
            .asObservable()
    }
    
    func getProccessingTransactions(
        of account: String
    ) -> [SolanaSDK.ParsedTransaction] {
        transactionsSubject.value
            .compactMap { pt -> SolanaSDK.ParsedTransaction? in
                // status
                let status: SolanaSDK.ParsedTransaction.Status
                
                switch pt.status {
                case .sending:
                    status = .requesting
                case .confirmed:
                    status = .processing(percent: 0)
                case .finalized:
                    status = .confirmed
                case .error(let error):
                    status = .error(error.readableDescription)
                }
                
                let signature = pt.transactionId
                
                var value: AnyHashable?
                let amountInFiat: Double?
                let fee: UInt64?
                
                switch pt.rawTransaction {
                case let transaction as ProcessTransaction.SendTransaction:
                    if transaction.sender.pubkey == account ||
                        transaction.receiver.address == account ||
                        transaction.authority == account
                    {
                        let amount = transaction.amount.convertToBalance(decimals: transaction.sender.token.decimals)
                        value = SolanaSDK.TransferTransaction(
                            source: transaction.sender,
                            destination: Wallet(pubkey: transaction.receiver.address, lamports: 0, token: transaction.sender.token),
                            authority: walletsRepository.nativeWallet?.pubkey,
                            destinationAuthority: nil,
                            amount: amount,
                            myAccount: transaction.sender.pubkey
                        )
                        amountInFiat = amount * pricesService.currentPrice(for: transaction.sender.token.symbol)?.value
                        fee = transaction.feeInSOL
                    } else {
                        return nil
                    }
                case let transaction as ProcessTransaction.OrcaSwapTransaction:
                    if transaction.sourceWallet.pubkey == account ||
                        transaction.destinationWallet.pubkey == account ||
                        transaction.authority == account
                    {
                        value = SolanaSDK.SwapTransaction(
                            source: transaction.sourceWallet,
                            sourceAmount: transaction.amount,
                            destination: transaction.destinationWallet,
                            destinationAmount: transaction.estimatedAmount,
                            myAccountSymbol: nil
                        )
                        amountInFiat = transaction.amount * pricesService.currentPrice(for: transaction.sourceWallet.token.symbol)?.value
                        fee = transaction.fees.networkFees?.total
                    } else {
                        return nil
                    }
                default:
                    return nil
                }
                
                return .init(status: status, signature: signature, value: value, amountInFiat: amountInFiat, slot: 0, blockTime: pt.sentAt, fee: fee, blockhash: nil)
            }
    }
}
