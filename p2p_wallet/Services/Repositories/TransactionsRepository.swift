//
//  TransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import Resolver
import RxSwift
import SolanaSwift
import TransactionParser

protocol TransactionsRepository {
    func getTransactionsHistory(
        account: String,
        accountSymbol: String?,
        before: String?,
        limit: Int,
        p2pFeePayerPubkeys: [String]
    ) -> Single<[SolanaSDK.ParsedTransaction]>
}

@available(*, deprecated, message: "Migrate to AccountStream")
class TransactionsRepositoryImpl: TransactionsRepository {
    // @Injected var solanaAPIClient: SolanaAPIClient
    // @Injected var transactionParsing: TransactionParserService

    func getTransactionsHistory(
        account _: String,
        accountSymbol _: String?,
        before _: String?,
        limit _: Int,
        p2pFeePayerPubkeys _: [String]
    ) -> Single<[SolanaSDK.ParsedTransaction]> {
        .just([])
    }
}
