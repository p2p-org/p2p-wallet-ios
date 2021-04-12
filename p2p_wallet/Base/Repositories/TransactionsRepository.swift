//
//  TransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import RxSwift

protocol TransactionsRepository {
    func getTransactionsHistory(account: String, accountSymbol: String?, before: String?, limit: Int) -> Single<[SolanaSDK.AnyTransaction]>
    func getTransaction(account: String, accountSymbol: String?, signature: String, parser: SolanaSDKTransactionParserType) -> Single<SolanaSDK.AnyTransaction>
}

extension SolanaSDK: TransactionsRepository {
    func getTransactionsHistory(account: String, accountSymbol: String?, before: String?, limit: Int) -> Single<[AnyTransaction]> {
        getConfirmedSignaturesForAddress2(account: account, configs: RequestConfiguration(limit: limit, before: before))
            .flatMap {activities in
                
                // construct parser
                let parser = SolanaSDK.TransactionParser(solanaSDK: self)
                
                // parse
                return Single.zip(activities.map { activity in
                    self.getTransaction(account: account, accountSymbol: accountSymbol, signature: activity.signature, parser: parser)
                        .map {
                            AnyTransaction(
                                signature: $0.signature,
                                value: $0.value,
                                slot: activity.slot,
                                blockTime: $0.blockTime
                            )
                        }
                })
            }
            .do(onSuccess: {transactions in
                Logger.log(message: "Fetched \(transactions.count) transactions", event: .debug)
            }, onError: {
                Logger.log(message: $0.readableDescription ?? "\($0)", event: .debug)
            })
    }
    
    func getTransaction(account: String, accountSymbol: String?, signature: String, parser: SolanaSDKTransactionParserType) -> Single<AnyTransaction> {
        getConfirmedTransaction(transactionSignature: signature)
            .flatMap { info in
                let time = info.blockTime != nil ? Date(timeIntervalSince1970: TimeInterval(info.blockTime!)): nil
                
                return parser.parse(transactionInfo: info, myAccount: account, myAccountSymbol: accountSymbol)
                    .map {
                        AnyTransaction(
                            signature: signature,
                            value: $0.value,
                            slot: nil,
                            blockTime: time)
                    }
                    .catchAndReturn(
                        AnyTransaction(
                            signature: signature,
                            value: nil,
                            slot: nil,
                            blockTime: time
                        )
                    )
            }
            .catchAndReturn(
                AnyTransaction(
                    signature: signature,
                    value: nil,
                    slot: nil,
                    blockTime: nil
                )
            )
    }
}
