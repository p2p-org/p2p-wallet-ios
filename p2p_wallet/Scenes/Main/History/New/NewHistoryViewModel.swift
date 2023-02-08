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
    case openDetailByRendableItem(_: any RendableDetailTransaction)
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
        let index = sections[0].items.firstIndex { searchingItem in
            item.id == searchingItem.id
        }
        guard let index = index else { return }
        actionSubject.send(.openDetailByRendableItem(MockedRendableDetailTransaction.items[index % MockedRendableDetailTransaction.items.count]))
    }
}
