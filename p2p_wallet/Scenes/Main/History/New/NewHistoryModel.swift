//
//  NewHistoryModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import Foundation
import History
import SolanaSwift

struct NewHistorySection: Identifiable, Equatable {
    let title: String
    let items: [NewHistoryItem]
    
    var id: String { title }
    
    static func == (lhs: NewHistorySection, rhs: NewHistorySection) -> Bool {
        lhs.id == rhs.id
    }
}

enum NewHistoryItem: Identifiable, Equatable {
    case rendable(any NewHistoryRendableItem)
    case button(id: String, title: String, action: () -> Void)
    case placeHolder(id: String, fetchable: Bool)
    
    var id: String {
        switch self {
        case let .rendable(item):
            return item.id
        case let .button(id, _, _):
            return id
        case let .placeHolder(id, _):
            return id
        }
    }
    
    static func == (lhs: NewHistoryItem, rhs: NewHistoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension Array where Element == NewHistoryItem {
    static func generatePlaceholder(n: Int) -> [NewHistoryItem] {
        var r: [NewHistoryItem] = []
        for _ in 0 ..< n {
            r.append(.placeHolder(id: UUID().uuidString, fetchable: n == 1))
        }
        return r
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
        self.tokens = []
//        tokens = trx.info?.tokens?.map { internalToken -> Token? in
//            allTokens.first { token in
//                token.address == internalToken.info.mint
//            }
//        }
//        .compactMap { $0 } ?? []
    }
    
    var id: String {
        trx.signature
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
        switch trx.info {
        case let .send(data):
            return icon(url: data.token.logoUrl, defaultIcon: .transactionSend)
        case let .receive(data):
            return icon(url: data.token.logoUrl, defaultIcon: .transactionReceive)
        case let .swap(data):
            guard
                let fromURL = data.from.token.logoUrl,
                let toURL = data.to.token.logoUrl
            else {
                return .icon(.buttonSwap)
            }
            return .double(fromURL, toURL)
        case let .createAccount(data):
            return icon(url: data.token.logoUrl, defaultIcon: .buyWallet)
        case let .closeAccount(data):
            return icon(url: data?.token.logoUrl, defaultIcon: .transactionCloseAccount)
        case let .mint(data):
            return icon(url: data.token.logoUrl, defaultIcon: .planet)
        case let .burn(data):
            return icon(url: data.token.logoUrl, defaultIcon: .planet)
        case let .stake(data):
            return icon(url: data.token.logoUrl, defaultIcon: .planet)
        case let .unstake(data):
            return icon(url: data.token.logoUrl, defaultIcon: .planet)
        case .unknown, .none:
            return .icon(.planet)
        }
    }
    
    var title: String {
        switch trx.info {
        case let .send(data):
            let target: String = data.account.username ?? RecipientFormatter.shortFormat(destination: data.account.address)
            return L10n.to(target)
        case let .receive(data):
            let source: String = data.account.username ?? RecipientFormatter.shortFormat(destination: data.account.address)
            return "\(L10n.from) \(source)"
        case let .swap(data):
            return L10n.to(data.from.token.symbol, data.to.token.symbol)
        case .stake:
            return L10n.stake
        case .unstake:
            return L10n.unstake
        case .mint:
            return L10n.mint
        case .burn:
            return L10n.burn
        case .createAccount:
            return L10n.createAccount
        case .closeAccount:
            return L10n.closeAccount
        case .unknown, .none:
            return L10n.unknown
        }
    }
    
    var subtitle: String {
        switch trx.info {
        case .send:
            return L10n.send
        case .receive:
            return L10n.receive
        case .swap:
            return L10n.swap
        case let .stake(data):
            return "\(L10n.voteAccount): \(RecipientFormatter.shortFormat(destination: data.account.address))"
        case let .unstake(data):
            return "\(L10n.voteAccount): \(RecipientFormatter.shortFormat(destination: data.account.address))"
        case .createAccount, .closeAccount:
            return RecipientFormatter.signature(signature: trx.signature)
        default:
            return "\(L10n.signature): \(RecipientFormatter.shortSignature(signature: trx.signature))"
        }
    }
    
    var detail: (NewHistoruItemChange, String) {
        switch trx.info {
        case let .send(data):
            return (.negative, "\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .receive(data):
            return (.positive, "+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .swap(data):
            return (.positive, "+\(data.to.amount.tokenAmount.tokenAmountFormattedString(symbol: data.to.token.symbol))")
        case let .burn(data):
            return (.negative, "\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .mint(data):
            return (.positive, "+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .stake(data):
            return (.negative, "+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .unstake(data):
            return (.positive, "+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .createAccount(data):
            return (.positive, "+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .closeAccount(data):
            if let data {
                return (.negative, "-\(data.amount.usdAmount.fiatAmountFormattedString())")
            } else {
                return (.unchanged, "")
            }
        case let .unknown(data):
            if data.amount.usdAmount >= 0 {
                return (.positive, "+\(data.amount.usdAmount.fiatAmountFormattedString())")
            } else {
                return (.positive, "\(data.amount.usdAmount.fiatAmountFormattedString())")
            }
        case .none:
            return (.unchanged, "")
        }
    
    }
    
    var subdetail: String {
        switch trx.info {
        case let .send(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .receive(data):
            return "+\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .swap(data):
            return "\(data.from.amount.tokenAmount.tokenAmountFormattedString(symbol: data.from.token.symbol))"
        case let .burn(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .mint(data):
            return "+\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .stake(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .unstake(data):
            return "+\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .createAccount(data):
            return "+\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .closeAccount(data):
            if let data {
                return "+\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
            } else {
                return ""
            }
        case let .unknown(data):
            if data.amount.usdAmount >= 0 {
                return "+\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
            } else {
                return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
            }
        case .none:
            return ""
        }
    }
        
    private func icon(url: URL?, defaultIcon: UIImage) -> NewHistoryRendableItemIcon {
        if let url = url {
            return .single(url)
        } else {
            return .icon(defaultIcon)
        }
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
