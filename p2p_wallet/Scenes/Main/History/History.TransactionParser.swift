//
// Created by Giang Long Tran on 15.04.2022.
//

import Foundation
import Resolver
import SolanaSwift
import TransactionParser

protocol HistoryTransactionParser {
    ///  Parse transaction.
    ///
    /// - Parameters:
    ///   - signatureInfo: the raw signature info
    ///   - transactionInfo: the raw transaction info
    ///   - account: the account that the transaction info belongs to.
    ///   - symbol: the token symbol that the transaction has to do.
    /// - Returns: parsed transaction
    func parse(
        signatureInfo: SignatureInfo,
        transactionInfo: TransactionInfo?,
        account: String?,
        symbol: String?
    ) async -> ParsedTransaction
}

extension History {
    typealias TransactionParser = HistoryTransactionParser

    /// The default transaction parser.
    class DefaultTransactionParser: TransactionParser {
        private let p2pFeePayers: [String]
        private let parser: TransactionParserService

        init(p2pFeePayers: [String]) {
            self.p2pFeePayers = p2pFeePayers
            parser = TransactionParserServiceImpl.default(apiClient: Resolver.resolve())
        }

        func parse(
            signatureInfo: SignatureInfo,
            transactionInfo: TransactionInfo?,
            account: String?,
            symbol: String?
        ) async -> ParsedTransaction {
            do {
                guard let transactionInfo = transactionInfo else { throw SolanaError.other("TransactionInfo is nil") }

                let parsedTrx = try await parser.parse(
                    transactionInfo,
                    config: .init(accountView: account, symbolView: symbol, feePayers: p2pFeePayers)
                )

                let time = transactionInfo
                    .blockTime != nil ? Date(timeIntervalSince1970: TimeInterval(transactionInfo.blockTime!)) : nil

                return .init(
                    status: parsedTrx.status,
                    signature: signatureInfo.signature,
                    info: parsedTrx.info,
                    slot: transactionInfo.slot,
                    blockTime: time,
                    fee: parsedTrx.fee,
                    blockhash: parsedTrx.blockhash
                )
            } catch {
                var blockTime: Date?
                if let time = signatureInfo.blockTime { blockTime = Date(timeIntervalSince1970: TimeInterval(time)) }
                return ParsedTransaction(
                    status: .confirmed,
                    signature: signatureInfo.signature,
                    info: nil,
                    slot: signatureInfo.slot,
                    blockTime: blockTime,
                    fee: nil,
                    blockhash: nil
                )
            }
        }
    }

    class CachingTransactionParsing: TransactionParser {
        private let delegate: TransactionParser
        private let cache = Utils.InMemoryCache<ParsedTransaction>(maxSize: 50)

        init(delegate: TransactionParser) { self.delegate = delegate }

        func parse(
            signatureInfo: SignatureInfo,
            transactionInfo: TransactionInfo?,
            account: String?,
            symbol: String?
        ) async -> ParsedTransaction {
            // Read from cache
            if let parsedTransaction = await cache.read(key: signatureInfo.signature) { return parsedTransaction }

            // Parse
            let parsedTransaction = await delegate.parse(
                signatureInfo: signatureInfo,
                transactionInfo: transactionInfo,
                account: account,
                symbol: symbol
            )
            await cache.write(key: signatureInfo.signature, data: parsedTransaction)
            return parsedTransaction
        }
    }
}
