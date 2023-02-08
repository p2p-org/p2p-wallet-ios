//
//  NewHistoryModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import Foundation
import SolanaSwift

struct NewHistorySection: Identifiable {
    let title: String
    let items: [NewHistoryItem]
    
    var id: String { title }
}

enum NewHistoryItem: Identifiable {
    case rendable(any NewHistoryRendableItem)
    case button(id: String, title: String, action: () -> Void)
    case placeHolder(id: String)
    
    var id: String {
        switch self {
        case let .rendable(item):
            return item.id
        case let .button(id, _, _):
            return id
        case let .placeHolder(id):
            return id
        }
    }
}

enum NewHistoryItemStatus {
    case success
    case pending
    case failed
}

enum NewHistoruItemChange {
    case positive
    case negative
}

protocol NewHistoryRendableItem: Identifiable {
    var id: String { get }
    
    var status: NewHistoryItemStatus { get }
    
    var change: NewHistoruItemChange { get }
    
    var icon: NewHistoryRendableItemIcon { get }

    var title: String { get }
    var subtitle: String { get }
    
    var detail: String { get }
    var subdetail: String { get }
}

enum NewHistoryRendableItemIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}

struct MockedHistoryRendableItem: NewHistoryRendableItem {
    var id: String
    
    var status: NewHistoryItemStatus
    
    var change: NewHistoruItemChange
    
    var icon: NewHistoryRendableItemIcon
    
    var title: String
    
    var subtitle: String
    
    var detail: String
    
    var subdetail: String
}

extension MockedHistoryRendableItem {
    static func pendingSend() -> Self {
        .init(
            id: UUID().uuidString,
            status: .pending,
            change: .negative,
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            title: "Sending...",
            subtitle: "To mad.p2p.sol",
            detail: "–$122.12",
            subdetail: "–5.21 SOL"
        )
    }
    
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
    
    static func swap() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .positive,
            icon: .double(
                URL(string: Token.nativeSolana.logoURI!)!,
                URL(string: Token.eth.logoURI!)!
            ),
            title: "Swap",
            subtitle: "SOL to ETH",
            detail: "+3.5 ETH",
            subdetail: "-120 SOL"
        )
    }
    
    static func burn() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .negative,
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            title: "Burn",
            subtitle: "Signature: ...Hs7s",
            detail: "–$5 268.65",
            subdetail: "–0.3271523 renBTC"
        )
    }
    
    static func mint() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .positive,
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            title: "Mint",
            subtitle: "Signature: ...Hs7s",
            detail: "$5 268.65",
            subdetail: "0.3271523 renBTC"
        )
    }
    
    static func stake() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .negative,
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            title: "Stake",
            subtitle: "Vote account: ....S39N",
            detail: "–$122.12",
            subdetail: "–5.21 SOL"
        )
    }
    
    static func unstake() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .positive,
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            title: "Unstake",
            subtitle: "Vote account: ....S39N",
            detail: "+$122.12",
            subdetail: "+5.21 SOL"
        )
    }
    
    static func create() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .positive,
            icon: .icon(.transactionCreateAccount),
            title: "Create account",
            subtitle: "5Rho...SheY",
            detail: "",
            subdetail: ""
        )
    }
    
    static func close() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .positive,
            icon: .icon(.transactionCloseAccount),
            title: "Close account",
            subtitle: "5Rho...SheY",
            detail: "",
            subdetail: ""
        )
    }
    
    static func unknown() -> Self {
        .init(
            id: UUID().uuidString,
            status: .success,
            change: .negative,
            icon: .icon(.planet),
            title: "Unknown",
            subtitle: "Signature: ...Hs7s",
            detail: "-$32.11",
            subdetail: "–1 SOL"
        )
    }
}
