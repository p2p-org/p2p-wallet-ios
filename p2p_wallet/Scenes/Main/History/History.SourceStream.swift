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
    func next(configuration: History.FetchingConfiguration) -> AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error>

    func first() async throws -> SolanaSDK.ParsedTransaction?

    /// Resets the stream.
    func reset()
}

extension History {
    typealias StreamSource = HistoryStreamSource

    struct FetchingConfiguration {
        /// The indicator that help to fetch all transactions before this time.
        let timestampEnd: Date

        let limit: Int
    }

    class MultipleAccountsStreamSource: StreamSource {
        private let sources: [StreamSource]

        init(sources: [StreamSource]) {
            self.sources = sources
            reset()
        }

        func first() async throws -> SolanaSDK.ParsedTransaction? {
            var mostFirst: SolanaSDK.ParsedTransaction?
            for source in sources {
                let trx = try await source.first()

                guard let t1 = trx?.blockTime else { continue }
                guard let t2 = mostFirst?.blockTime else {
                    mostFirst = trx
                    continue
                }

                if t1 > t2 {
                    mostFirst = trx
                }
            }
            return mostFirst
        }

        func next(configuration: FetchingConfiguration) -> AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> {
            AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> { stream in
                Task {
                    do {
                        for source in sources {
                            for try await transaction in source.next(configuration: configuration) {
                                stream.yield(transaction)
                            }
                        }
                        stream.finish(throwing: nil)
                    } catch {
                        stream.finish(throwing: error)
                    }
                }
            }
        }

        func reset() {
            for source in sources { source.reset() }
        }
    }

    class AccountStreamSource: StreamSource {
        let transactionRepository: TransactionRepository

        /// The object that is responsible for parsing transactions
        let transactionParser: TransactionParser

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
            transactionRepository: TransactionRepository,
            transactionParser: TransactionParser
        ) {
            self.account = account
            self.accountSymbol = accountSymbol
            self.transactionRepository = transactionRepository
            self.transactionParser = transactionParser
        }

        func first() async throws -> SolanaSDK.ParsedTransaction? {
            guard let signatureInfo = try await transactionRepository.getSignatures(
                address: account,
                limit: 1,
                before: latestFetchedSignature
            ).first else { return nil }

            let transactionInfo = try await transactionRepository.getTransaction(signature: signatureInfo.signature)

            return try await transactionParser.parse(
                signatureInfo: signatureInfo,
                transactionInfo: transactionInfo,
                account: account,
                symbol: accountSymbol
            )
        }

        func next(configuration: FetchingConfiguration) -> AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> {
            AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> { stream in
                Task {
                    do {
                        while true {
                            // Fetch transaction signatures
                            let signatureInfos = try await transactionRepository.getSignatures(
                                address: account,
                                limit: configuration.limit,
                                before: latestFetchedSignature
                            )

                            if signatureInfos.isEmpty {
                                stream.finish(throwing: nil)
                                return
                            }

                            // Fetch transaction and parse it
                            for signatureInfo in signatureInfos {
                                let signature = signatureInfo.signature

                                // Fetch transaction info
                                let transactionInfo = try await transactionRepository
                                    .getTransaction(signature: signature)

                                // Parse transaction
                                let transaction = try await transactionParser.parse(
                                    signatureInfo: signatureInfo,
                                    transactionInfo: transactionInfo,
                                    account: account,
                                    symbol: accountSymbol
                                )

                                let transactionTime = transaction.blockTime ?? Date()
                                print(
                                    transactionTime,
                                    configuration.timestampEnd,
                                    transactionTime >= configuration.timestampEnd
                                )

                                latestFetchedSignature = signature

                                if transactionTime >= configuration.timestampEnd {
                                    // Emit transction
                                    stream.yield(transaction)
                                } else {
                                    // Break stream and return
                                    stream.finish(throwing: nil)
                                    return
                                }
                            }
                        }
                    } catch {
                        stream.finish(throwing: error)
                    }
                }
            }
        }

        func reset() { latestFetchedSignature = nil }
    }
}
