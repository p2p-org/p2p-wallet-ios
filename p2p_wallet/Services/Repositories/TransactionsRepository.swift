//
//  TransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import RxSwift

protocol TransactionsRepository {
    func getTransactionsHistory(
        account: String,
        accountSymbol: String?,
        before: String?,
        limit: Int,
        p2pFeePayerPubkeys: [String]
    ) -> Single<[SolanaSDK.ParsedTransaction]>
}

extension SolanaSDK: TransactionsRepository {
    func getTransactionsHistory(
        account: String,
        accountSymbol: String?,
        before: String?,
        limit: Int,
        p2pFeePayerPubkeys: [String]
    ) -> Single<[SolanaSDK.ParsedTransaction]> {
        getSignaturesForAddress(address: account, configs: RequestConfiguration(limit: limit, before: before))
            .flatMap { [weak self] activities in
                guard let self = self else { throw Error.unknown }
                // construct parser
                let parser = SolanaSDK.TransactionParser(solanaSDK: self)

                // parse
                return Single.zip(try activities.map { [weak self] activity in
                    guard let self = self else { throw Error.unknown }
                    return self.getTransaction(
                        account: account,
                        accountSymbol: accountSymbol,
                        signature: activity.signature,
                        parser: parser,
                        p2pFeePayerPubkeys: p2pFeePayerPubkeys
                    )
                    .map {
                        SolanaSDK.ParsedTransaction(
                            status: $0.status,
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
            .do(onSuccess: { transactions in
                Logger.log(message: "Fetched \(transactions.count) transactions", event: .debug)
            }, onError: {
                Logger.log(message: $0.readableDescription, event: .debug)
            })
    }

    func getTransaction(
        account: String,
        accountSymbol: String?,
        signature: String,
        parser: SolanaSDKTransactionParserType,
        p2pFeePayerPubkeys: [String]
    ) -> Single<SolanaSDK.ParsedTransaction> {
        getTransaction(transactionSignature: signature)
            .flatMap { info in
                let time = info.blockTime != nil ? Date(timeIntervalSince1970: TimeInterval(info.blockTime!)) : nil

                return parser.parse(
                    transactionInfo: info,
                    myAccount: account,
                    myAccountSymbol: accountSymbol,
                    p2pFeePayerPubkeys: p2pFeePayerPubkeys
                )
                .map {
                    SolanaSDK.ParsedTransaction(
                        status: $0.status,
                        signature: signature,
                        value: $0.value,
                        slot: nil,
                        blockTime: time,
                        fee: $0.fee,
                        blockhash: $0.blockhash
                    )
                }
                .catchAndReturn(
                    SolanaSDK.ParsedTransaction(
                        status: .confirmed,
                        signature: signature,
                        value: nil,
                        slot: nil,
                        blockTime: time,
                        fee: .init(transaction: info.meta?.fee ?? 0, accountBalances: 0),
                        blockhash: info.transaction.message.recentBlockhash
                    )
                )
            }
            .catchAndReturn(
                SolanaSDK.ParsedTransaction(
                    status: .confirmed,
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
