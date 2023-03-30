//
//  RendableDetailTransaction+ParsedTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Combine
import Foundation
import SolanaSwift
import TransactionParser

struct RendableDetailParsedTransaction: RendableTransactionDetail {
    let trx: ParsedTransaction

    var status: TransactionDetailStatus {
        switch trx.status {
        case .confirmed:
            return .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted)
        case .requesting, .processing:
            return .loading(message: L10n.theTransactionIsBeingProcessed)
        case let .error(error):
            return .error(message: NSAttributedString(string: error ?? ""), error: trx.status.getError())
        }
    }

    var title: String {
        switch trx.status {
        case .confirmed:
            return L10n.transactionSucceeded
        case .requesting, .processing:
            return L10n.transactionSubmitted
        case .error:
            return L10n.transactionFailed
        }
    }

    var subtitle: String {
        trx.blockTime?.string(withFormat: "MMMM dd, yyyy @ HH:mm", locale: Locale.base) ?? ""
    }

    var signature: String? {
        trx.signature ?? ""
    }

    var icon: TransactionDetailIcon {
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

    var amountInFiat: TransactionDetailChange {
        .unchanged("")
    }

    var amountInToken: String {
        if let info = trx.info as? SwapInfo {
            if let amount = info.destinationAmount {
                return amount.tokenAmountFormattedString(symbol: info.source?.token.symbol ?? "")
            }
        } else if let info = trx.info as? TransferInfo {
            if let amount = info.amount {
                return amount.tokenAmountFormattedString(symbol: info.source?.token.symbol ?? "")
            }
        }
        return ""
    }

    var extra: [TransactionDetailExtraInfo] {
        var result: [TransactionDetailExtraInfo] = []

        if let info = trx.info as? TransferInfo {
            result.append(
                .init(title: L10n.sendTo, value: RecipientFormatter.format(destination: info.destination?.pubkey ?? ""))
            )
        } else if let info = trx.info as? CloseAccountInfo {
            result.append(
                .init(
                    title: "Account closed",
                    value: RecipientFormatter.format(destination: info.closedWallet?.pubkey ?? "")
                )
            )
        } else if let info = trx.info as? CreateAccountInfo {
            result.append(
                .init(
                    title: "Account created",
                    value: RecipientFormatter.format(destination: info.newWallet?.pubkey ?? "")
                )
            )
        }

        let feeAmountFormatted: Double = trx.fee?.total.convertToBalance(decimals: Token.nativeSolana.decimals) ?? 0.0
        result
            .append(.init(title: L10n.transactionFee,
                          value: trx.paidByP2POrg ? L10n.freePaidByKeyApp : "\(feeAmountFormatted) SOL"))

        return result
    }

    var actions: [TransactionDetailAction] = [.share, .explorer]

    var buttonTitle: String {
        L10n.done
    }
}
