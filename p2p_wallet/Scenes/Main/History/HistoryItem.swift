//
//  HistoryItem.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/12/2022.
//

import Foundation
import TransactionParser

enum HistoryItem: Hashable {
    case parsedTransaction(ParsedTransaction)
    case sellTransaction(SellDataServiceTransaction)
    
    var signature: String? {
        switch self {
        case .parsedTransaction(let transaction):
            return transaction.signature
        case .sellTransaction(let transaction):
            return transaction.id
        }
    }
    
    var blockTime: Date? {
        switch self {
        case .parsedTransaction(let transaction):
            return transaction.blockTime
        case .sellTransaction(let transaction):
            return transaction.createdAt
        }
    }
}
