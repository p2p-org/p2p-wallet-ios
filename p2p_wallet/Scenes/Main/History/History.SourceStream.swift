//
// Created by Giang Long Tran on 12.04.2022.
//

import Foundation

import BECollectionView
import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

protocol HistoryStreamSource {
    /// Fetches new transaction signatures sequencely.
    func next(_ configuration: History.FetchingConfiguration) async throws -> [History.TransactionSignature]

    /// Resets the stream.
    func reset()
}

extension History {
    typealias StreamSource = HistoryStreamSource

    struct TransactionSignature {
        /// The account address
        let account: String

        /// The account's token symbol
        let accountSymbol: String

        // Meta data about signature
        let signatureInfo: SolanaSDK.SignatureInfo

        init(account: String, accountSymbol: String, signatureInfo: SolanaSDK.SignatureInfo) {
            self.account = account
            self.accountSymbol = accountSymbol
            self.signatureInfo = signatureInfo
        }
    }

    struct FetchingConfiguration {
        let feePayer: [String]
        let limit: Int
    }

    class AccountStreamSource: StreamSource {
        let solanaSDK: SolanaSDK

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
            solanaSDK: SolanaSDK = Resolver.resolve()
        ) {
            self.account = account
            self.accountSymbol = accountSymbol
            self.solanaSDK = solanaSDK
        }

        func next(_ configuration: History.FetchingConfiguration) async throws -> [History.TransactionSignature] {
            try await solanaSDK
                .getSignaturesForAddress(
                    address: account,
                    configs: .init(limit: configuration.limit, before: latestFetchedSignature)
                )
                .map { [weak self] infos -> [History.TransactionSignature] in
                    infos
                        .map {
                            TransactionSignature(
                                account: self?.account ?? "",
                                accountSymbol: self?.accountSymbol ?? "",
                                signatureInfo: $0
                            )
                        }
                }
                .do(onSuccess: { [weak self] transactionSignature in
                    self?.latestFetchedSignature = transactionSignature.last?.signatureInfo.signature
                })
                .value
        }

        func reset() { latestFetchedSignature = nil }
    }
}
