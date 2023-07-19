//
//  NewHistorySection.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation

struct HistorySection: Identifiable, Equatable {
    let title: String
    let items: [NewHistoryItem]

    var id: String { title }

    static func == (lhs: HistorySection, rhs: HistorySection) -> Bool {
        lhs.id == rhs.id
    }
}

enum NewHistoryItem: Identifiable, Equatable {
    case rendableTransaction(any RendableListTransactionItem)
    case rendableOffram(any RendableListOfframItem)

    case button(id: String, title: String, action: () -> Void)
    case placeHolder(id: String)
    case fetch(id: String)

    var id: String {
        switch self {
        case let .rendableTransaction(item):
            return item.id
        case let .rendableOffram(item):
            return item.id
        case let .button(id, _, _), let .placeHolder(id), let .fetch(id):
            return id
        }
    }

    static func == (lhs: NewHistoryItem, rhs: NewHistoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension Array where Element == NewHistoryItem {
    static func generatePlaceholder(n: Int) -> [NewHistoryItem] {
        var r: [NewHistoryItem] = []
        for _ in 0 ..< n {
            r.append(.placeHolder(id: UUID().uuidString))
        }
        return r
    }
}
