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

protocol RendableTransactionDetail {
    var status: TransactionDetailStatus { get }
    
    var title: String { get }
    
    var subtitle: String { get }
    
    var signature: String? { get }
    
    var icon: TransactionDetailIcon { get }
    
    var amountInFiat: TransactionDetailChange { get }
    
    var amountInToken: String { get }
    
    var extra: [TransactionDetailExtraInfo] { get }
    
    var actions: [TransactionDetailAction] { get }
    
    var buttonTitle: String { get }
}

struct TransactionDetailExtraInfo {
    let title: String
    let value: String
    
    let copyableValue: String?
    
    init(title: String, value: String, copyableValue: String? = nil) {
        self.title = title
        self.value = value
        self.copyableValue = copyableValue
    }
}

enum TransactionDetailAction: Int, Identifiable {
    var id: Int { self.rawValue }
    
    case share
    case explorer
}

enum TransactionDetailIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}

enum TransactionDetailChange {
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

enum TransactionDetailStatus {
    case loading(message: String)
    case succeed(message: String)
    case error(message: NSAttributedString, error: Error?)
}

extension TransactionDetailStatus: Equatable {
    static func == (lhs: TransactionDetailStatus, rhs: TransactionDetailStatus) -> Bool {
        switch (lhs, rhs) {
        case let (.loading(lhsMessage), .loading(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.succeed(lhsMessage), .succeed(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.error(lhsMessage, lhsError), .error(rhsMessage, rhsError)):
            return lhsMessage == rhsMessage && lhsError?.localizedDescription == rhsError?.localizedDescription
        default:
            return false
        }
    }
}
