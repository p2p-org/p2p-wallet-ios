//
//  RendableListTransactionItem+PendingTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation
import KeyAppKitCore
import SolanaSwift

struct RendableListPendingTransactionItem: RendableListTransactionItem {
    let trx: PendingTransaction

    let uuid: String = UUID().uuidString

    var id: String {
        trx.transactionId ?? uuid
    }

    var date: Date {
        trx.sentAt
    }

    var status: RendableListTransactionItemStatus {
        if trx.transactionId != nil {
            return .success
        } else {
            switch trx.status {
            case .error:
                return .failed
            default:
                return .pending
            }
        }
    }

    var icon: RendableListTransactionItemIcon {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            if
                let urlStr = transaction.walletToken.token.logoURI,
                let url = URL(string: urlStr)
            {
                return .single(url)
            } else {
                return .icon(.transactionSend)
            }

        case let transaction as SwapRawTransactionType:
            let fromUrlStr = transaction.sourceWallet.token.logoURI
            let toUrlStr = transaction.destinationWallet.token.logoURI

            guard let fromUrlStr, let toUrlStr else {
                return .icon(.buttonSwap)
            }

            let fromUrl = URL(string: fromUrlStr)
            let toUrl = URL(string: toUrlStr)

            guard let fromUrl, let toUrl else {
                return .icon(.buttonSwap)
            }

            return .double(fromUrl, toUrl)

        case let transaction as WormholeClaimTransaction:
            guard let url = transaction.token.logo else {
                return .icon(.planet)
            }

            return .single(url)

        case let transaction as WormholeSendTransaction:
            if
                let urlStr = transaction.account.data.token.logoURI,
                let url = URL(string: urlStr)
            {
                return .single(url)
            } else {
                return .icon(.transactionSend)
            }
            
        case let transaction as ClaimSentViaLinkTransaction:
            if
                let urlStr = transaction.token.logoURI,
                let url = URL(string: urlStr)
            {
                return .single(url)
            } else {
                return .icon(.transactionReceive)
            }
        default:
            return .icon(.planet)
        }
    }

    var title: String {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            switch transaction.recipient.category {
            case let .username(name, domain):
                return L10n.to("\(name).\(domain)")
            case let .solanaTokenAddress(walletAddress, _):
                return L10n.to(RecipientFormatter.shortFormat(destination: walletAddress.base58EncodedString))
            case .solanaAddress:
                return L10n.to(RecipientFormatter.shortFormat(destination: transaction.recipient.address))
            default:
                return L10n.to
            }

        case let transaction as SwapRawTransactionType:
            return L10n.to(transaction.sourceWallet.token.symbol, transaction.destinationWallet.token.symbol)

        case let transaction as WormholeClaimTransaction:
            return "Wormhole"

        case let transaction as WormholeSendTransaction:
            return "Wormhole"

        case let transaction as ClaimSentViaLinkTransaction:
            guard let pubkey = try? PublicKey(string: transaction.claimableTokenInfo.account)
            else { return L10n.receive}
            return L10n.receivedFrom + " " + pubkey.short()

        default:
            return L10n.unknown
        }
    }

    var subtitle: String {
        switch trx.status {
        case .error:
            switch trx.rawTransaction {
            case _ as SendTransaction:
                return "\(L10n.send)"

            case _ as SwapRawTransactionType:
                return "\(L10n.swap)"

            case let transaction as WormholeClaimTransaction:
                return "Claim"

            case let transaction as WormholeSendTransaction:
                return "Send"

            case _ as ClaimSentViaLinkTransaction:
                return "\(L10n.sendViaOneTimeLink)"

            default:
                return "\(L10n.transactionFailed)"
            }

        default:
            switch trx.rawTransaction {
            case _ as SendTransaction:
                if trx.transactionId == nil {
                    return "\(L10n.sending).."
                } else {
                    return "\(L10n.send)"
                }

            case _ as SwapRawTransactionType:
                if trx.transactionId == nil {
                    return "\(L10n.swapping).."
                } else {
                    return "\(L10n.swap)"
                }

            case _ as ClaimSentViaLinkTransaction:
                if trx.transactionId == nil {
                    return "\(L10n.processing).."
                } else {
                    return "\(L10n.proceed)"
                }

            default:
                if trx.transactionId == nil {
                    return "\(L10n.processing).."
                } else {
                    return "\(L10n.proceed)"
                }
            }
        }
    }

    var detail: (RendableListTransactionItemChange, String) {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            return (.negative, "-\(transaction.amountInFiat.fiatAmountFormattedString())")

        case let transaction as SwapRawTransactionType:
            return (
                .positive,
                "+\(transaction.toAmount.tokenAmountFormattedString(symbol: transaction.destinationWallet.token.symbol))"
            )

        case let transaction as WormholeSendTransaction:
            let amount = CurrencyFormatter().string(amount: transaction.currencyAmount)
            return (.negative, "-\(amount)")

        case let transaction as WormholeClaimTransaction:
            if let currencyAmount = transaction.amountInFiat {
                let amount = CurrencyFormatter().string(amount: currencyAmount)
                return (.positive, "+\(amount)")
            } else {
                return (.unchanged, "")
            }

        case let transaction as ClaimSentViaLinkTransaction:
            return (.positive, "+\(transaction.tokenAmount.tokenAmountFormattedString(symbol: transaction.token.symbol))")

        default:
            return (.unchanged, "")
        }
    }

    var subdetail: String {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            return "-\(transaction.amount.tokenAmountFormattedString(symbol: transaction.walletToken.token.symbol))"

        case let transaction as SwapRawTransactionType:
            return "-\(transaction.fromAmount.tokenAmountFormattedString(symbol: transaction.sourceWallet.token.symbol))"

        case let transaction as WormholeSendTransaction:
            return CryptoFormatter().string(for: transaction.amount) ?? ""

        case let transaction as WormholeClaimTransaction:
            return CryptoFormatter().string(for: transaction.amountInCrypto) ?? ""

        case let transaction as ClaimSentViaLinkTransaction:
            return ""

        default:
            return ""
        }
    }

    var onTap: (() -> Void)?
}
