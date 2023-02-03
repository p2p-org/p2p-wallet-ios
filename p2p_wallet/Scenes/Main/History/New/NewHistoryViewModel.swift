//
//  NewHistoryViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 01.02.2023.
//

import Combine
import Foundation
import SolanaSwift

class NewHistoryViewModel: BaseViewModel, ObservableObject {
    typealias ProcessingItem = String
    typealias HistoryItem = NewHistoryRendableItem
    
    @Published var processingItems: [ProcessingItem] = []
    @Published var sections: [NewHistorySection] = []
    
    init(initialSections: [NewHistorySection]) {
        sections = initialSections
    }
}
