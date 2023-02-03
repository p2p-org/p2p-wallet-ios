//
//  DetailTransactionModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import Foundation

struct DetailTransactionExtraInfo {
    let title: String
    let value: String
    
    let copyable: Bool
}

enum DetailTransactionIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}

protocol RendableDetailTransaction {
    var signature: String { get }
    var icon: DetailTransactionIcon { get }
    var title: String { get }
    var subtitle: String { get }
    var extra: [DetailTransactionExtraInfo] { get }
}

struct MockedRendableDetailTransaction: RendableDetailTransaction {
    var signature: String
    var icon: DetailTransactionIcon
    var title: String
    var subtitle: String
    var extra: [DetailTransactionExtraInfo]
}


