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
    @Published var rendableTransaction: any RendableTransactionDetail

    @Published var closeButtonTitle: String = L10n.done

    let style: TransactionDetailStyle

    let action: PassthroughSubject<TransactionDetailViewModelOutput, Never> = .init()

    init(rendableDetailTransaction: any RendableTransactionDetail, style: TransactionDetailStyle = .active) {
        self.style = style
        self.rendableTransaction = rendableDetailTransaction
    }

    init(parsedTransaction: ParsedTransaction) {
        self.style = .passive
        self.rendableTransaction = RendableDetailParsedTransaction(trx: parsedTransaction)
    }

    init(historyTransaction: HistoryTransaction) {
        self.style = .passive
        self.rendableTransaction = RendableDetailHistoryTransaction(trx: historyTransaction, allTokens: [])

        super.init()

        Task {
            let tokenRepository: TokensRepository = Resolver.resolve()
            self.rendableTransaction = try await RendableDetailHistoryTransaction(trx: historyTransaction, allTokens: tokenRepository.getTokensList(useCache: true))
        }
    }

    init(pendingTransaction: PendingTransaction) {
        let pendingService: TransactionHandlerType = Resolver.resolve()
        let priceService: PricesService = Resolver.resolve()

        self.style = .active
        self.rendableTransaction = RendableDetailPendingTransaction(trx: pendingTransaction, priceService: priceService)

        super.init()

        pendingService
            .observeTransaction(transactionIndex: pendingTransaction.trxIndex)
            .sink { trx in
                guard let trx = trx else { return }
                self.rendableTransaction = RendableDetailPendingTransaction(trx: trx, priceService: priceService)
            }
            .store(in: &subscriptions)
    }

    func share() {
        guard let url = URL(string: "https://explorer.solana.com/tx/\(rendableTransaction.signature ?? "")") else { return }
        action.send(.share(url))
    }

    func explore() {
        guard let url = URL(string: "https://explorer.solana.com/tx/\(rendableTransaction.signature ?? "")") else { return }
        action.send(.open(url))
    }
}
