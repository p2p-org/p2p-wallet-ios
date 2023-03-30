//
//  RendableListTransactionItem+ParsedTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation
import Resolver
import SolanaPricesAPIs
import SolanaSwift
import TransactionParser

struct RendableListParsedTransactionItem: RendableListTransactionItem {
    let trx: ParsedTransaction

    let priceService: PricesService

    var onTap: (() -> Void)?

    var id: String {
        trx.signature ?? ""
    }

    var date: Date {
        trx.blockTime ?? Date()
    }

    var status: RendableListTransactionItemStatus {
        switch trx.status {
        case .requesting, .processing:
            return .pending
        case .confirmed:
            return .success
        case .error:
            return .failed
        }
    }

    var icon: RendableListTransactionItemIcon {
        if let info = trx.info as? SwapInfo {
            if
                let sourceImage = info.source?.token.logoURI,
                let sourceURL = URL(string: sourceImage),
                let destinationImage = info.destination?.token.logoURI,
                let destinationURL = URL(string: destinationImage)

            {
                return .double(sourceURL, destinationURL)
            }
        } else if let info = trx.info as? TransferInfo {
            if
                let sourceImage = info.source?.token.logoURI,
                let sourceURL = URL(string: sourceImage)
            {
                return .single(sourceURL)
            }
        } else if trx.info is CloseAccountInfo {
            return .icon(.closeToken)
        } else if trx.info is CreateAccountInfo {
            return .icon(.transactionCreateAccount)
        }

        return .icon(.planet)
    }

    var title: String {
        if let info = trx.info as? SwapInfo {
            return "\(info.source?.token.symbol ?? "") to \(info.destination?.token.symbol ?? "")"
        } else if let info = trx.info as? TransferInfo {
            switch info.transferType {
            case .send:
                return "To \(RecipientFormatter.shortFormat(destination: info.destination?.pubkey ?? ""))"
            default:
                return "From \(RecipientFormatter.shortFormat(destination: info.destination?.pubkey ?? ""))"
            }
        } else if trx.info is CloseAccountInfo {
            return "Close account"
        } else if trx.info is CreateAccountInfo {
            return "Create account"
        }

        return "Unknown"
    }

    var subtitle: String {
        if trx.info is SwapInfo {
            return "Swap"
        } else if trx.info is TransferInfo {
            return "Send"
        } else if let info = trx.info as? CloseAccountInfo {
            return RecipientFormatter.format(destination: info.closedWallet?.pubkey ?? "")
        } else if let info = trx.info as? CreateAccountInfo {
            return RecipientFormatter.format(destination: info.newWallet?.pubkey ?? "")
        }

        return "Signature: \(RecipientFormatter.shortSignature(signature: trx.signature ?? ""))"
    }

    var detail: (RendableListTransactionItemChange, String) {
//        var symbol: String?
//        if let info = trx.info as? SwapInfo {
//            symbol = info.symbol
//        } else if let info = trx.info as? TransferInfo {
//            symbol = info.symbol
//        }
//
//        if let symbol {
//            let priceService: PricesService = Resolver.resolve()
//            let price = priceService.getCurrentPrice(for: symbol)
//            return (price ?? 0 * trx.amount).fiatAmountFormattedString(customFormattForLessThan1E_2: true)
//        }

        return (.unchanged, "")
    }

    var subdetail: String {
        if let info = trx.info as? SwapInfo {
            if let amount = info.destinationAmount {
                let amountText = amount.tokenAmountFormattedString(symbol: info.source?.token.symbol ?? "")
                return "\(amountText)"
            }
        } else if let info = trx.info as? TransferInfo {
            if let amount = info.amount {
                let amountText = amount.tokenAmountFormattedString(symbol: info.source?.token.symbol ?? "")
                switch info.transferType {
                case .send:
                    return "\(amountText)"
                default:
                    return "+\(amountText)"
                }
            }
        }
        return ""
    }
}
