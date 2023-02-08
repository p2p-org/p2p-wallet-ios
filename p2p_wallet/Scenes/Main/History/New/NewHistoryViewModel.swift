//
//  NewHistoryViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 01.02.2023.
//

import Combine
import Foundation
import SolanaSwift

enum NewHistoryAction {
    /// For demo only!
    case openDetailByID(id: TransactionID)
}

class NewHistoryViewModel: BaseViewModel, ObservableObject {
    typealias ProcessingItem = String
    typealias HistoryItem = NewHistoryRendableItem
    
    @Published var processingItems: [ProcessingItem] = []
    @Published var sections: [NewHistorySection] = []
    
    let actionSubject = PassthroughSubject<NewHistoryAction, Never>()
    
    init(initialSections: [NewHistorySection]) {
        sections = initialSections
    }
    
    func onTap(item: any NewHistoryRendableItem) {
        actionSubject.send(.openDetailByID(id: item.id))
    }
}
