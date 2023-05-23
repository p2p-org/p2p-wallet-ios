//
//  NewHistoryListItem+Mock.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation
import SolanaSwift

struct MockedRendableListTransactionItem: RendableListTransactionItem {
    var id: String
    
    var date: Date
    
    var status: RendableListTransactionItemStatus
    
    var icon: RendableListTransactionItemIcon
    
    var title: String
    
    var subtitle: String
    
    var detail: (RendableListTransactionItemChange, String)
    
    var subdetail: String
    
    var onTap: (() -> Void)? = nil
}

extension MockedRendableListTransactionItem {
    static func pendingSend() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .pending,
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            title: "Sending...",
            subtitle: "To mad.p2p.sol",
            detail: (.negative, "–$122.12"),
            subdetail: "–5.21 SOL"
        )
    }
    
    static func send() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            title: "Send",
            subtitle: "To mad.p2p.sol",
            detail: (.negative, "–$122.12"),
            subdetail: "–5.21 SOL"
        )
    }
    
    static func failedSend() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .failed,
            
            icon: .single(URL(string: Token.usdc.logoURI!)!),
            title: "Send",
            subtitle: "To mad.p2p.sol",
            detail: (.negative, "–$34.36"),
            subdetail: "–34.36 USDC"
        )
    }
    
    static func receive() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            title: "Receive",
            subtitle: "From ...S39N",
            detail: (.unchanged, ""),
            subdetail: "+0.3271523 renBTC"
        )
    }
    
    static func swap() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .double(
                URL(string: Token.nativeSolana.logoURI!)!,
                URL(string: Token.eth.logoURI!)!
            ),
            title: "Swap",
            subtitle: "SOL to ETH",
            detail: (.positive, "+3.5 ETH"),
            subdetail: "-120 SOL"
        )
    }
    
    static func burn() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            title: "Burn",
            subtitle: "Signature: ...Hs7s",
            detail: (.negative, "–$5 268.65"),
            subdetail: "–0.3271523 renBTC"
        )
    }
    
    static func mint() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            title: "Mint",
            subtitle: "Signature: ...Hs7s",
            detail: (.positive, "$5 268.65"),
            subdetail: "0.3271523 renBTC"
        )
    }
    
    static func stake() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            title: "Stake",
            subtitle: "Vote account: ....S39N",
            detail: (.negative, "–$122.12"),
            subdetail: "–5.21 SOL"
        )
    }
    
    static func unstake() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            title: "Unstake",
            subtitle: "Vote account: ....S39N",
            detail: (.positive, "+$122.12"),
            subdetail: "+5.21 SOL"
        )
    }
    
    static func create() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .icon(.transactionCreateAccount),
            title: "Create account",
            subtitle: "5Rho...SheY",
            detail: (.unchanged, ""),
            subdetail: ""
        )
    }
    
    static func close() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .icon(.transactionCloseAccount),
            title: "Close account",
            subtitle: "5Rho...SheY",
            detail: (.unchanged, ""),
            subdetail: ""
        )
    }
    
    static func unknown() -> Self {
        .init(
            id: UUID().uuidString,
            date: Date(),
            status: .success,
            icon: .icon(.planet),
            title: "Unknown",
            subtitle: "Signature: ...Hs7s",
            detail: (.negative, "-$32.11"),
            subdetail: "–1 SOL"
        )
    }
}
