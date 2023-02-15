//
//  NewHistoryModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import Foundation
import History
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
    case unchanged
    case negative
}

protocol NewHistoryRendableItem: Identifiable {
    var id: String { get }
    
    var date: Date { get }
    
    var status: NewHistoryItemStatus { get }
    
    var icon: NewHistoryRendableItemIcon { get }

    var title: String { get }
    
    var subtitle: String { get }
    
    var detail: (NewHistoruItemChange, String) { get }
    
    var subdetail: String { get }
}

enum NewHistoryRendableItemIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}

struct MockedHistoryRendableItem: NewHistoryRendableItem {
    var id: String
    
    var date: Date
    
    var status: NewHistoryItemStatus
    
    var icon: NewHistoryRendableItemIcon
    
    var title: String
    
    var subtitle: String
    
    var detail: (NewHistoruItemChange, String)
    
    var subdetail: String
}

struct RendableHistoryTransactionListItem: NewHistoryRendableItem {
    private var trx: HistoryTransaction
    
    private var tokens: [Token]
    
    init(trx: HistoryTransaction, allTokens: [Token]) {
        self.trx = trx
        
        tokens = trx.info.tokens?.map { internalToken -> Token? in
            allTokens.first { token in
                token.address == internalToken.info.mint
            }
        }
        .compactMap { $0 } ?? []
    }
    
    var id: String {
        trx.txSignature
    }
    
    var date: Date {
        trx.date
    }
    
    var status: NewHistoryItemStatus {
        switch trx.status {
        case .success:
            return .success
        case .failure:
            return .failed
        }
    }
    
    var icon: NewHistoryRendableItemIcon {
        switch trx.type {
        case .swap:
            let tokenA = trx.info.tokens?.first(where: { $0.info.swapRole == "swap_token_a" })
            let tokenB = trx.info.tokens?.first(where: { $0.info.swapRole == "swap_token_b" })
            
            guard let tokenA, let tokenB else {
                return .icon(.transactionSwap)
            }
            
            let solanaTokenA = tokens.first(where: { $0.address == tokenA.info.mint })
            let solanaTokenB = tokens.first(where: { $0.address == tokenB.info.mint })
            
            guard let solanaTokenA, let solanaTokenB else {
                return .icon(.transactionSwap)
            }
            
            guard
                let urlStrA = solanaTokenA.logoURI,
                let urlA = URL(string: urlStrA),
                let urlStrB = solanaTokenB.logoURI,
                let urlB = URL(string: urlStrB)
            else {
                return .icon(.transactionSwap)
            }
            
            return .double(urlA, urlB)
                
        case .createAccount:
            return .icon(.transactionCreateAccount)
        case .closeAccount:
            return .icon(.transactionCloseAccount)
        case .unknown:
            return .icon(.planet)
            
        default:
            if let urlStr = tokens.first?.logoURI, let url = URL(string: urlStr) {
                return .single(url)
            } else {
                return .icon(.transactionSend)
            }
        }
    }
    
    var title: String {
        switch trx.type {
        case .swap:
            if let swapProgramNames = trx.info.swapPrograms?.map(\.name).compactMap({ $0 }).joined(separator: ", ") {
                return "\(L10n.swap) (\(swapProgramNames)"
            } else {
                return "\(L10n.swap)"
            }
        case .stake:
            return "\(L10n.stake)"
        case .unstake:
            return "\(L10n.unstake)"
        case .send:
            return "\(L10n.send)"
        case .receive:
            return "\(L10n.receive)"
        case .mint:
            return "\(L10n.mint)"
        case .burn:
            return "\(L10n.burn)"
        case .createAccount:
            return "\(L10n.createAccount)"
        case .closeAccount:
            return "\(L10n.closeAccount)"
        case .unknown:
            return "\(L10n.unknown)"
        }
    }
    
    var subtitle: String {
        switch trx.type {
        case .swap:
            let tokenASymbol = trx.info.tokens?.first(where: { $0.info.swapRole == "swap_token_a" })?.info.symbol
            let tokenBSymbol = trx.info.tokens?.first(where: { $0.info.swapRole == "swap_token_b" })?.info.symbol
            
            guard let tokenASymbol, let tokenBSymbol else {
                return ""
            }
            
            return L10n.to(tokenASymbol, tokenBSymbol)
        case .send:
            let counterparty = trx.info.counterparty
            return L10n.to(counterparty?.username ?? RecipientFormatter.shortFormat(destination: counterparty?.address ?? ""))
        case .receive:
            let counterparty = trx.info.counterparty
            return "\(L10n.from) \(counterparty?.username ?? RecipientFormatter.shortFormat(destination: counterparty?.address ?? ""))"
        default:
            return "\(L10n.signature): \(RecipientFormatter.shortSignature(signature: trx.txSignature))"
        }
    }
    
    var detail: (NewHistoruItemChange, String) {
        return (.unchanged, "")
    }
    
    var subdetail: String {
        return ""
    }
}

extension MockedHistoryRendableItem {
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
            detail: (.positive, "+$5 268.65"),
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
