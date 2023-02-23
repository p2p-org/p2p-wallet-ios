//
//  DetailTransactionModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import Combine
import Foundation
import History
import SolanaSwift
import TransactionParser

protocol RendableDetailTransaction {
    var status: DetailTransactionStatus { get }
    
    var title: String { get }
    
    var subtitle: String { get }
    
    var signature: String? { get }
    
    var icon: DetailTransactionIcon { get }
    
    var amountInFiat: DetailTransactionChange { get }
    
    var amountInToken: String { get }
    
    var extra: [DetailTransactionExtraInfo] { get }
    
    var actions: [DetailTransactionAction] { get }
}

struct DetailTransactionExtraInfo {
    let title: String
    let value: String
    
    let copyableValue: String?
    
    init(title: String, value: String, copyableValue: String? = nil) {
        self.title = title
        self.value = value
        self.copyableValue = copyableValue
    }
}

enum DetailTransactionAction: Int, Identifiable {
    var id: Int { self.rawValue }
    
    case share
    case explorer
}

enum DetailTransactionIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}

enum DetailTransactionChange {
    case positive(String)
    case negative(String)
    case unchanged(String)
    
    var value: String {
        switch self {
        case let .positive(value): return value
        case let .negative(value): return value
        case let .unchanged(value): return value
        }
    }
}

enum DetailTransactionStatus: Equatable {
    case loading(message: String)
    case succeed(message: String)
    case error(message: NSAttributedString)
}
