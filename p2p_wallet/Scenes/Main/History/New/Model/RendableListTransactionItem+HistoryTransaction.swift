//
//  NewHistoryRendableListItem+HistoryTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation
import History
import SolanaSwift

struct RendableListHistoryTransactionItem: RendableListTransactionItem {
    let trx: HistoryTransaction

    // Use to map history token to solana token. They are identical but we need to extract png images.
    private let allTokens: Set<SolanaSwift.Token>

    init(trx: HistoryTransaction, allTokens: Set<SolanaSwift.Token>, onTap: (() -> Void)? = nil) {
        self.trx = trx
        self.allTokens = allTokens
        self.onTap = onTap
    }

    var id: String {
        trx.signature
    }

    var onTap: (() -> Void)?

    var date: Date {
        trx.date
    }

    var status: RendableListTransactionItemStatus {
        switch trx.status {
        case .success:
            return .success
        case .failed:
            return .failed
        }
    }

    var icon: RendableListTransactionItemIcon {
        switch trx.info {
        case let .send(data):
            return icon(mint: data.token.mint, url: data.token.logoUrl, defaultIcon: .transactionSend)
            
        case let .receive(data):
            return icon(mint: data.token.mint, url: data.token.logoUrl, defaultIcon: .transactionReceive)
            
        case let .swap(data):
            guard
                let fromIcon = resolveTokenIconURL(
                    mint: data.from.token.mint,
                    fallbackImageURL: data.from.token.logoUrl
                ),
                let toIcon = resolveTokenIconURL(mint: data.to.token.mint, fallbackImageURL: data.to.token.logoUrl)
            else {
                return .icon(.buttonSwap)
            }

            return .double(fromIcon, toIcon)
            
        case let .createAccount(data):
            return icon(mint: data.token.mint, url: data.token.logoUrl, defaultIcon: .buyWallet)
            
        case let .closeAccount(data):
            return icon(mint: data?.token.mint, url: data?.token.logoUrl, defaultIcon: .transactionCloseAccount)
            
        case let .mint(data):
            return icon(mint: data.token.mint, url: data.token.logoUrl, defaultIcon: .planet)
            
        case let .burn(data):
            return icon(mint: data.token.mint, url: data.token.logoUrl, defaultIcon: .planet)
            
        case let .stake(data):
            return icon(mint: data.token.mint, url: data.token.logoUrl, defaultIcon: .planet)
            
        case let .unstake(data):
            return icon(mint: data.token.mint, url: data.token.logoUrl, defaultIcon: .planet)
            
        case let .wormholeSend(data):
            return icon(mint: data.tokenAmount.token.mint, url: data.tokenAmount.token.logoUrl, defaultIcon: .planet)
            
        case let .wormholeReceive(data):
            return icon(mint: data.tokenAmount.token.mint, url: data.tokenAmount.token.logoUrl, defaultIcon: .planet)
            
        case .unknown, .none:
            return .icon(.planet)
        }
    }

    var title: String {
        switch trx.info {
        case let .send(data):
            let target: String = data.account.name ?? RecipientFormatter.shortFormat(destination: data.account.address)
            return L10n.to(target)
        case let .receive(data):
            let source: String = data.account.name ?? RecipientFormatter.shortFormat(destination: data.account.address)
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
        case .wormholeSend:
            return "Ethereum network"
        case .wormholeReceive:
            return "Ethereum network"
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
        case .wormholeSend:
            return "Send"
        case .wormholeReceive:
            return "Claim"
        default:
            return "\(L10n.signature): \(RecipientFormatter.shortSignature(signature: trx.signature))"
        }
    }

    var detail: (RendableListTransactionItemChange, String) {
        switch trx.info {
        case let .send(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return (.unchanged, "")
            }
            return (.negative, "-\(usdAmount.fiatAmountFormattedString())")

        case let .receive(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return (.unchanged, "")
            }
            return (.positive, "+\(usdAmount.fiatAmountFormattedString())")

        case let .swap(data):
            return (
                .positive,
                "+\(data.to.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.to.token.symbol))"
            )
            
        case let .burn(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return (.unchanged, "")
            }

            return (.negative, "-\((-usdAmount).fiatAmountFormattedString())")

        case let .mint(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return (.unchanged, "")
            }
            return (.positive, "+\(usdAmount.fiatAmountFormattedString())")

        case let .stake(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return (.unchanged, "")
            }
            return (.negative, "-\(usdAmount.fiatAmountFormattedString())")

        case let .unstake(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return (.unchanged, "")
            }
            return (.positive, "+\(usdAmount.fiatAmountFormattedString())")

        case let .createAccount(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return (.unchanged, "")
            }
            return (.positive, "+\(usdAmount.fiatAmountFormattedString())")

        case let .closeAccount(data):
            if let data {
                guard let usdAmount = data.amount.usdAmountDouble else {
                    return (.unchanged, "")
                }
                return (.negative, "-\(usdAmount.fiatAmountFormattedString())")
            } else {
                return (.unchanged, "")
            }

        case let .unknown(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return (.unchanged, "")
            }

            if usdAmount >= 0 {
                return (.positive, "+\(usdAmount.fiatAmountFormattedString())")
            } else {
                return (.negative, "\(usdAmount.fiatAmountFormattedString())")
            }

        case let .wormholeSend(data):
            guard let usdAmount = data.tokenAmount.amount.usdAmountDouble else {
                return (.unchanged, "")
            }
            return (.negative, "-\(usdAmount.fiatAmountFormattedString())")

        case let .wormholeReceive(data):
            guard let usdAmount = data.tokenAmount.amount.usdAmountDouble else {
                return (.unchanged, "")
            }
            return (.positive, "+\(usdAmount.fiatAmountFormattedString())")

        case .none:
            return (.unchanged, "")
        }
    }

    var subdetail: String {
        switch trx.info {
        case let .send(data):
            return "-\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .receive(data):
            return "+\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .swap(data):
            return "\(data.from.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.from.token.symbol))"

        case let .burn(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .mint(data):
            return "+\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .stake(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .unstake(data):
            return "+\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .createAccount(data):
            return "+\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .closeAccount(data):
            if let data {
                return "+\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"
            } else {
                return ""
            }
        case let .unknown(data):
            if data.amount.usdAmountDouble >= 0 {
                return "+\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"
            } else {
                return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"
            }

        case let .wormholeSend(data):
            return "-\(data.tokenAmount.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.tokenAmount.token.symbol))"

        case let .wormholeReceive(data):
            return "+\(data.tokenAmount.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.tokenAmount.token.symbol))"

        case .none:
            return ""
        }
    }

    /// Resolve token icon url
    private func resolveTokenIconURL(mint: String?, fallbackImageURL: URL?) -> URL? {
        if
            let mint,
            let urlStr: String = allTokens.first(where: { $0.address == mint })?.logoURI,
            let url = URL(string: urlStr)
        {
            return url
        } else if let fallbackImageURL {
            return fallbackImageURL
        }

        return nil
    }

    private func icon(mint: String?, url: URL?, defaultIcon: UIImage) -> RendableListTransactionItemIcon {
        if let url = resolveTokenIconURL(mint: mint, fallbackImageURL: url) {
            return .single(url)
        } else {
            return .icon(defaultIcon)
        }
    }
}
