//
//  DetailTransactionViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import Combine
import Foundation
import TransactionParser

enum DetailTransactionStyle {
    case active
    case passive
}

enum DetailTransactionViewModelOutput {
    case share(URL)
    case close
}

class DetailTransactionViewModel: BaseViewModel, ObservableObject {
    @Published var rendableTransaction: any RendableDetailTransaction

    @Published var closeButtonTitle: String = L10n.done

    let style: DetailTransactionStyle

    let action: PassthroughSubject<DetailTransactionViewModelOutput, Never> = .init()

    init(rendableDetailTransaction: any RendableDetailTransaction, style: DetailTransactionStyle = .active) {
        self.style = style
        self.rendableTransaction = rendableDetailTransaction
    }

    init(parsedTransaction: ParsedTransaction, style: DetailTransactionStyle = .active) {
        self.style = style
        self.rendableTransaction = RendableDetailParsedTransaction(trx: parsedTransaction)
    }

    func share() {
        guard let url = URL(string: "https://explorer.solana.com/tx/\(rendableTransaction.signature ?? "")") else { return }
        action.send(.share(url))
    }
    
    func explore() {
        guard let url = URL(string: "https://explorer.solana.com/tx/\(rendableTransaction.signature ?? "")") else { return }
        UIApplication.shared.open(url)
    }
}
