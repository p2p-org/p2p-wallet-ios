//
//  TransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import RxSwift

protocol TransactionsRepository {
    func getTransactionsHistory(account: String, accountSymbol: String?, before: String?, limit: Int, p2pFeePayerPubkeys: [String]) -> Single<[SolanaSDK.AnyTransaction]>
    func getTransaction(account: String, accountSymbol: String?, signature: String, parser: SolanaSDKTransactionParserType, p2pFeePayerPubkeys: [String]) -> Single<SolanaSDK.AnyTransaction>
}

extension SolanaSDK: TransactionsRepository {
    func getTransactionsHistory(account: String, accountSymbol: String?, before: String?, limit: Int, p2pFeePayerPubkeys: [String]) -> Single<[AnyTransaction]> {
        getConfirmedSignaturesForAddress2(account: account, configs: RequestConfiguration(limit: limit, before: before))
            .flatMap {activities in
                
                // construct parser
                let parser = SolanaSDK.TransactionParser(solanaSDK: self)
                
                // parse
                return Single.zip(activities.map { activity in
                    self.getTransaction(account: account, accountSymbol: accountSymbol, signature: activity.signature, parser: parser, p2pFeePayerPubkeys: p2pFeePayerPubkeys)
                        .map {
                            AnyTransaction(
                                signature: $0.signature,
                                value: $0.value,
                                slot: activity.slot,
                                blockTime: $0.blockTime,
                                fee: $0.fee,
                                blockhash: $0.blockhash
                            )
                        }
                })
            }
            .do(onSuccess: {transactions in
                Logger.log(message: "Fetched \(transactions.count) transactions", event: .debug)
            }, onError: {
                Logger.log(message: $0.readableDescription, event: .debug)
            })
    }
    
    func getTransaction(account: String, accountSymbol: String?, signature: String, parser: SolanaSDKTransactionParserType, p2pFeePayerPubkeys: [String]) -> Single<AnyTransaction> {
        getConfirmedTransaction(transactionSignature: signature)
            .flatMap { info in
                let time = info.blockTime != nil ? Date(timeIntervalSince1970: TimeInterval(info.blockTime!)): nil
                
                return parser.parse(transactionInfo: info, myAccount: account, myAccountSymbol: accountSymbol, p2pFeePayerPubkeys: p2pFeePayerPubkeys)
                    .map {
                        AnyTransaction(
                            signature: signature,
                            value: $0.value,
                            slot: nil,
                            blockTime: time,
                            fee: $0.fee,
                            blockhash: $0.blockhash
                        )
                    }
                    .catchAndReturn(
                        AnyTransaction(
                            signature: signature,
                            value: nil,
                            slot: nil,
                            blockTime: time,
                            fee: info.meta?.fee,
                            blockhash: info.transaction.message.recentBlockhash
                        )
                    )
            }
            .catchAndReturn(
                AnyTransaction(
                    signature: signature,
                    value: nil,
                    slot: nil,
                    blockTime: nil,
                    fee: nil,
                    blockhash: nil
                )
            )
    }
}
