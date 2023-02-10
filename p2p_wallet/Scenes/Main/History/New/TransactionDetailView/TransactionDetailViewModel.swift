//
//  DetailTransactionViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import Foundation
import Combine
import TransactionParser

enum DetailTransactionStyle {
    case active
    case passive
}

class DetailTransactionViewModel: BaseViewModel, ObservableObject {
    @Published var rendableTransaction: any RendableDetailTransaction
    
    @Published var closeButtonTitle: String = L10n.done

    let style: DetailTransactionStyle
    
    let close = PassthroughSubject<Void, Never>()
    
    init(rendableDetailTransaction: any RendableDetailTransaction, style: DetailTransactionStyle = .active) {
        self.style = style
        self.rendableTransaction = rendableDetailTransaction
    }
    
    init(parsedTransaction: ParsedTransaction, style: DetailTransactionStyle = .active) {
        self.style = style
        self.rendableTransaction = RendableDetailParsedTransaction(trx: parsedTransaction)
    }
}

