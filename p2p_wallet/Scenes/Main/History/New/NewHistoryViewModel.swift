//
//  NewHistoryViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 01.02.2023.
//

import Combine
import Foundation
import SolanaSwift

enum NewHistoryItemStatus {
    case success
    case failed
}

enum NewHistoruItemChange {
    case positive
    case negative
}

protocol NewHistoryItem: Identifiable {
    var id: String { get }
    
    var status: NewHistoryItemStatus { get }
    var change: NewHistoruItemChange { get }
    
    var icon: NewHistoryItemIcon { get }

    var title: String { get }
    var subtitle: String { get }
    
    var detail: String { get }
    var subdetail: String { get }
}

enum NewHistoryItemIcon {
    case single(URL)
    case double(URL, URL)
}

struct BaseHistoryItem: NewHistoryItem {
    var id: String
    
    var status: NewHistoryItemStatus
    
    var change: NewHistoruItemChange
    
    var icon: NewHistoryItemIcon
    
    var title: String
    
    var subtitle: String
    
    var detail: String
    
    var subdetail: String
    
    static func send() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .negative,
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            title: "Send",
            subtitle: "To mad.p2p.sol",
            detail: "–$122.12",
            subdetail: "–5.21 SOL"
        )
    }
    
    static func failedSend() -> Self {
        .init(
            id: UUID().uuidString,
            status: .failed,
            change: .negative,
            icon: .single(URL(string: Token.usdc.logoURI!)!),
            title: "Send",
            subtitle: "To mad.p2p.sol",
            detail: "–$34.36",
            subdetail: "–34.36 USDC"
        )
    }
    
    static func receive() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .positive,
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            title: "Receive",
            subtitle: "From ...S39N",
            detail: "+$5 268.65",
            subdetail: "+0.3271523 renBTC"
        )
    }
}

class NewHistoryViewModel: BaseViewModel, ObservableObject {
    typealias ProcessingItem = String
    typealias HistoryItem = NewHistoryItem
    
    @Published var processingItems: [ProcessingItem] = []
    @Published var historyItems: [any HistoryItem] = []
    
    init(initialHistoryItem: [any HistoryItem]) {
        historyItems = initialHistoryItem
    }
}
