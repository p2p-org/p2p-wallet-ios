//
//  NewHistoryModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import Foundation
import History
import SolanaSwift

protocol RendableListTransactionItem: Identifiable {
    var id: String { get }
    
    var date: Date { get }
    
    var status: NewHistoryRendableListTransactionItemStatus { get }
    
    var icon: NewHistoryRendableListTransactionItemIcon { get }

    var title: String { get }
    
    var subtitle: String { get }
    
    var detail: (NewHistoryRendableListTransactionItemChange, String) { get }
    
    var subdetail: String { get }
    
    var onTap: (() -> Void)? { get set }
}

enum NewHistoryRendableListTransactionItemStatus {
    case success
    case pending
    case failed
}

enum NewHistoryRendableListTransactionItemChange {
    case positive
    case unchanged
    case negative
}

enum NewHistoryRendableListTransactionItemIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}
