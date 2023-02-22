//
//  NewHistoryRendableListSellItem.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation

protocol RendableListOfframItem: Identifiable {
    var id: String { get }
    
    var date: Date { get }
    
    var status: RendableListOfframStatus { get }
    
    var title: String { get }
    
    var subtitle: String { get }
    
    var detail: String { get }
    
    var onTap: (() -> Void)? { get }
}

enum RendableListOfframStatus {
    case ready
    case error
}
