//
//  DetailTransactionViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import Foundation
import Combine

class DetailTransactionViewModel: BaseViewModel, ObservableObject {
    @Published var rendableTransaction: any RendableDetailTransaction
    
    @Published var closeButtonTitle: String = L10n.done
    
    let close = PassthroughSubject<Void, Never>()
    
    init(rendableTransaction: any RendableDetailTransaction) {
        self.rendableTransaction = rendableTransaction
    }
}
