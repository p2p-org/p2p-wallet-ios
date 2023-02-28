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
    
    var status: RendableListTransactionItemStatus { get }
    
    var icon: RendableListTransactionItemIcon { get }

    var title: String { get }
    
    var subtitle: String { get }
    
    var detail: (RendableListTransactionItemChange, String) { get }
    
    var subdetail: String { get }
    
    var onTap: (() -> Void)? { get set }
}

enum RendableListTransactionItemStatus {
    case success
    case pending
    case failed
}

enum RendableListTransactionItemChange {
    case positive
    case unchanged
    case negative
}

enum RendableListTransactionItemIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}
