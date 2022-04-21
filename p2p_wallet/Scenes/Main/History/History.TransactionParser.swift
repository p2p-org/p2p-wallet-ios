//
// Created by Giang Long Tran on 15.04.2022.
//

import Foundation
import SolanaSwift

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
        signatureInfo: SolanaSDK.SignatureInfo,
        transactionInfo: SolanaSDK.TransactionInfo,
        account: String,
        symbol: String
    ) async throws -> SolanaSDK.ParsedTransaction
}

extension History {
    typealias TransactionParser = HistoryTransactionParser

    /// The default transaction parser.
    class DefaultTransactionParser: TransactionParser {
        private let p2pFeePayers: [String]
        private let parser: SolanaSDKTransactionParserType

        init(p2pFeePayers: [String]) {
            self.p2pFeePayers = p2pFeePayers
            parser = SolanaSDK.TransactionParser(solanaSDK: Resolver.resolve())
        }

        func parse(
            signatureInfo: SolanaSDK.SignatureInfo,
            transactionInfo: SolanaSDK.TransactionInfo,
            account: String,
            symbol: String
        ) async throws -> SolanaSDK.ParsedTransaction {
            let parsedTrx = try await parser.parse(
                transactionInfo: transactionInfo,
                myAccount: account,
                myAccountSymbol: symbol,
                p2pFeePayerPubkeys: p2pFeePayers
            ).value

            let time = transactionInfo
                .blockTime != nil ? Date(timeIntervalSince1970: TimeInterval(transactionInfo.blockTime!)) : nil

            return .init(
                status: parsedTrx.status,
                signature: signatureInfo.signature,
                value: parsedTrx.value,
                slot: transactionInfo.slot,
                blockTime: time,
                fee: parsedTrx.fee,
                blockhash: parsedTrx.blockhash
            )
        }
    }

    class CachingTransactionParsing: TransactionParser, Cachable {
        private let delegate: TransactionParser
        private let cache = Utils.InMemoryCache<SolanaSDK.ParsedTransaction>(maxSize: 50)

        init(delegate: TransactionParser) { self.delegate = delegate }

        func parse(
            signatureInfo: SolanaSDK.SignatureInfo,
            transactionInfo: SolanaSDK.TransactionInfo,
            account: String,
            symbol: String
        ) async throws -> SolanaSDK.ParsedTransaction {
            // Read from cache
            var parsedTransaction = cache.read(key: signatureInfo.signature)
            if let parsedTransaction = parsedTransaction { return parsedTransaction }
            // Parse
            parsedTransaction = try await delegate.parse(
                signatureInfo: signatureInfo,
                transactionInfo: transactionInfo,
                account: account,
                symbol: symbol
            )
            cache.write(key: signatureInfo.signature, data: parsedTransaction!)
            return parsedTransaction!
        }

        func clear() {
            cache.clear()
        }
    }
}
