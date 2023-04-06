//
//  DetailTransactionViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import Combine
import Foundation
import History
import Resolver
import SolanaSwift
import TransactionParser

enum TransactionDetailStyle {
    case active
    case passive
}

enum TransactionDetailViewModelOutput {
    case share(URL)
    case open(URL)
    case close
}

class TransactionDetailViewModel: BaseViewModel, ObservableObject {
    @Injected private var transactionHandler: TransactionHandler
    @Published var rendableTransaction: any RendableTransactionDetail

    let style: TransactionDetailStyle

    let action = PassthroughSubject<TransactionDetailViewModelOutput, Never>()

    var statusContext: String?

    init(rendableDetailTransaction: any RendableTransactionDetail, style: TransactionDetailStyle = .active) {
        self.style = style
        rendableTransaction = rendableDetailTransaction
    }

    init(parsedTransaction: ParsedTransaction) {
        style = .passive
        rendableTransaction = RendableDetailParsedTransaction(trx: parsedTransaction)
    }

    init(historyTransaction: HistoryTransaction) {
        style = .passive
        rendableTransaction = RendableDetailHistoryTransaction(trx: historyTransaction, allTokens: [])

        super.init()

        Task {
            let tokenRepository: TokensRepository = Resolver.resolve()
            self.rendableTransaction = try await RendableDetailHistoryTransaction(
                trx: historyTransaction,
                allTokens: tokenRepository.getTokensList(useCache: true)
            )
        }
    }

    init(pendingTransaction: PendingTransaction, statusContext: String? = nil) {
        let pendingService: TransactionHandlerType = Resolver.resolve()
        let priceService: PricesService = Resolver.resolve()

        style = .active
        self.statusContext = statusContext
        rendableTransaction = RendableDetailPendingTransaction(trx: pendingTransaction, priceService: priceService)

        super.init()

        pendingService
            .observeTransaction(transactionIndex: pendingTransaction.trxIndex)
            .sink { trx in
                guard let trx = trx else { return }
                self.rendableTransaction = RendableDetailPendingTransaction(trx: trx, priceService: priceService)
            }
            .store(in: &subscriptions)
    }

    convenience init(submit rawTransaction: RawTransactionType) {
        let pendingService: TransactionHandlerType = Resolver.resolve()

        let idx = pendingService.sendTransaction(rawTransaction, errorHandler: nil)
        let pendingTransaction = pendingService.getProcessingTransaction(index: idx)

        self.init(pendingTransaction: pendingTransaction)
    }

    func share() {
        guard let url = URL(string: "https://explorer.solana.com/tx/\(rendableTransaction.signature ?? "")")
        else { return }
        action.send(.share(url))
    }

    func explore() {
        guard let url = URL(string: "https://explorer.solana.com/tx/\(rendableTransaction.signature ?? "")")
        else { return }
        action.send(.open(url))
    }
}
