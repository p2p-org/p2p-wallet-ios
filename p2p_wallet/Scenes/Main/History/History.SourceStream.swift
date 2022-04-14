//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

protocol HistoryStreamSource {
    /// Fetches new transactions sequencely.
    func next(_ configuration: History.FetchingConfiguration) -> Single<[SolanaSDK.ParsedTransaction]>

    /// Resets the stream.
    func reset()
}

extension History {
    typealias StreamSource = HistoryStreamSource

    struct FetchingConfiguration {
        let feePayer: [String]
        let limit: Int
    }

    class AccountStreamSource: StreamSource {
        let transactionsRepository: TransactionsRepository

        /// The account address
        private let account: String

        /// The account's token symbol
        private let accountSymbol: String

        /// The most latest signature of transactions, that has been loaded.
        /// This value will be used as pagination indicator and all next transactions after this one will be loaded.
        private var latestFetchedSignature: String?

        init(
            account: String,
            accountSymbol: String,
            transactionsRepository: TransactionsRepository = Resolver.resolve()
        ) {
            self.account = account
            self.accountSymbol = accountSymbol
            self.transactionsRepository = transactionsRepository
        }

        func next(_ configuration: History.FetchingConfiguration) -> Single<[SolanaSDK.ParsedTransaction]> {
            transactionsRepository
                .getTransactionsHistory(
                    account: account,
                    accountSymbol: accountSymbol,
                    before: latestFetchedSignature,
                    limit: configuration.limit,
                    p2pFeePayerPubkeys: configuration.feePayer
                )
                .do(onSuccess: { [weak self] transactions in
                    self?.latestFetchedSignature = transactions.last?.signature
                })
        }

        func reset() { latestFetchedSignature = nil }
    }
}
