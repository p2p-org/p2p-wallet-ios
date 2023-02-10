//
//  NewHistoryRepository.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 09.02.2023.
//

import Foundation
import History
import Resolver
import SolanaSwift
import TransactionParser
import SolanaPricesAPIs

protocol NewHistoryRepository {
    func clear() async
    func fetch(_ count: Int) async throws -> [any NewHistoryRendableItem]
}

class EmptyNewHistoryRepository: NewHistoryRepository {
    func clear() async {}
    func fetch(_ count: Int) async throws -> [any NewHistoryRendableItem] { [] }
}

actor NewHistoryRepositoryWithOldProvider: NewHistoryRepository {
    @Injected private var priceService: PricesService

    var source: HistoryStreamSource = EmptyStreamSource()

    @Injected private var transactionParserRepository: TransactionParsedRepository

    private let transactionRepository = SolanaTransactionRepository(solanaAPIClient: Resolver.resolve())

    private var loadedSignatures: [TransactionID] = []

    init(source: HistoryStreamSource) {
        self.source = source
    }

    func clear() async {
        loadedSignatures = []
    }

    func fetch(_ count: Int) async throws -> [any NewHistoryRendableItem] {
        let signatures = try await fetchSignatures(count)
        let parsedTransactions = try await parseTransaction(signatures: signatures)

        return parsedTransactions.map { RendableParsedTransaction(trx: $0, price: nil) }
    }

    private func parseTransaction(signatures: [HistoryStreamSource.Result]) async throws -> [ParsedTransaction] {
        let transactions = try await transactionRepository
            .getTransactions(signatures: signatures.map(\.signatureInfo.signature))
        var parsedTransactions: [ParsedTransaction] = []

        for trxInfo in transactions {
            guard let trxInfo = trxInfo else { continue }
            guard let (signature, account, symbol) = signatures
                .first(where: { (signatureInfo: SignatureInfo, _, _) in
                    signatureInfo.signature == trxInfo.transaction.signatures.first
                }) else { continue }

            parsedTransactions.append(
                await transactionParserRepository.parse(
                    signatureInfo: signature,
                    transactionInfo: trxInfo,
                    account: account,
                    symbol: symbol
                )
            )
        }

        return parsedTransactions
    }

    private func fetchSignatures(_ count: Int) async throws -> [HistoryStreamSource.Result] {
        var results: [HistoryStreamSource.Result] = []
        do {
            while true {
                let firstTrx = try await source.currentItem()
                guard
                    let firstTrx = firstTrx,
                    let rawTime = firstTrx.0.blockTime
                else {
                    return results
                }

                // Fetch next 1 days
                var timeEndFilter = Date(timeIntervalSince1970: TimeInterval(rawTime))
                timeEndFilter = timeEndFilter.addingTimeInterval(-1 * 60 * 60 * 24 * 1)

                if Task.isCancelled { return results }
                while let result = try await source.next(configuration: .init(timestampEnd: timeEndFilter))
                {
                    let (signatureInfo, _, _) = result

                    // Skip duplicated transaction
                    if Task.isCancelled { return results }
                    if loadedSignatures.contains(where: { $0 == signatureInfo.signature }) { continue }
                    if results
                        .contains(where: { $0.0.signature == signatureInfo.signature }) { continue }

                    if Task.isCancelled { return results }
                    // Save signature
                    loadedSignatures.append(signatureInfo.signature)
                    results.append(result)

                    if results.count > 15 {
                        return results
                    }
                }
            }
        } catch {
            return results
        }
    }
}

struct RendableParsedTransaction: NewHistoryRendableItem {
    let trx: ParsedTransaction
    
    var price: CurrentPrice?

    var id: String {
        trx.signature ?? ""
    }

    var date: Date {
        trx.blockTime ?? Date()
    }

    var status: NewHistoryItemStatus {
        switch trx.status {
        case .requesting, .processing:
            return .pending
        case .confirmed:
            return .success
        case .error:
            return .failed
        }
    }

    var change: NewHistoruItemChange {
        if trx.amount >= 0 {
            return .positive
        } else {
            return .negative
        }
    }

    var icon: NewHistoryRendableItemIcon {
        if let info = trx.info as? SwapInfo {
            if
                let sourceImage = info.source?.token.logoURI,
                let sourceURL = URL(string: sourceImage),
                let destinationImage = info.destination?.token.logoURI,
                let destinationURL = URL(string: destinationImage)

            {
                return .double(sourceURL, destinationURL)
            }
        } else if let info = trx.info as? TransferInfo {
            if
                let sourceImage = info.source?.token.logoURI,
                let sourceURL = URL(string: sourceImage)
            {
                return .single(sourceURL)
            }
        } else if let info = trx.info as? CloseAccountInfo {
            return .icon(.closeToken)
        } else if let info = trx.info as? CreateAccountInfo {
            return .icon(.transactionCreateAccount)
        }

        return .icon(.planet)
    }

    var title: String {
        if let info = trx.info as? SwapInfo {
            return "\(info.source?.token.symbol ?? "") to \(info.destination?.token.symbol ?? "")"
        } else if let info = trx.info as? TransferInfo {
            return "To \(RecipientFormatter.shortFormat(destination: info.destination?.pubkey ?? ""))"
        } else if let info = trx.info as? CloseAccountInfo {
            return "Close account"
        } else if let info = trx.info as? CreateAccountInfo {
            return "Create account"
        }

        return "Unknown"
    }

    var subtitle: String {
        if let info = trx.info as? SwapInfo {
            return "Swap"
        } else if let info = trx.info as? TransferInfo {
            return "Send"
        } else if let info = trx.info as? CloseAccountInfo {
            return RecipientFormatter.format(destination: info.closedWallet?.pubkey ?? "")
        } else if let info = trx.info as? CreateAccountInfo {
            return RecipientFormatter.format(destination: info.newWallet?.pubkey ?? "")
        }

        return "Signature: \(RecipientFormatter.shortSignature(signature: trx.signature ?? ""))"
    }

    var detail: String {
        return ""
    }

    var subdetail: String {
        if let info = trx.info as? SwapInfo {
            if let amount = info.destinationAmount {
                return amount.tokenAmountFormattedString(symbol: info.source?.token.symbol ?? "")
            }
        } else if let info = trx.info as? TransferInfo {
            if let amount = info.amount {
                return amount.tokenAmountFormattedString(symbol: info.source?.token.symbol ?? "")
            }
        }
        return ""
    }
}
