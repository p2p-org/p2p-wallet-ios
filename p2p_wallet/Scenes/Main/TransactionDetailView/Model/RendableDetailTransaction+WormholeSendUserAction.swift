//
//  RendableDetailTransaction+PendingTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Send
import Wormhole

struct RendableWormholeSendUserActionDetail: RenderableTransactionDetail {
    let userAction: WormholeSendUserAction

    var signature: String? { userAction.id }

    var status: TransactionDetailStatus {
        switch userAction.status {
        case .pending, .processing:
            return .loading(message: L10n.itUsuallyTakes1520MinutesForATransactionToComplete)
        case .ready:
            return .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted)
        case let .error(error):
            return .error(
                message: NSAttributedString(string: L10n.OopsSomethingWentWrong.pleaseTryAgainLater),
                error: error
            )
        }
    }

    var title: String {
        switch userAction.status {
        case .pending, .processing:
            return L10n.transactionSubmitted
        case .ready:
            return L10n.transactionSucceeded
        case let .error(error):
            return L10n.transactionFailed
        }
    }

    var subtitle: String {
        userAction.createdDate.string(withFormat: "MMMM dd, yyyy @ HH:mm", locale: Locale.base)
    }

    var icon: TransactionDetailIcon {
        if
            let urlStr = userAction.sourceToken.logoURI,
            let url = URL(string: urlStr)
        {
            return .single(url)
        }

        return .icon(.transactionSend)
    }

    var amountInFiat: TransactionDetailChange {
        if let currencyAmount = userAction.currencyAmount {
            let value = CurrencyFormatter().string(amount: currencyAmount)
            return .negative("-\(value)")
        } else {
            return .unchanged("")
        }
    }

    var amountInToken: String {
        let value = CryptoFormatter().string(amount: userAction.amount)
        return "\(value)"
    }

    var extra: [TransactionDetailExtraInfo] {
        var result: [TransactionDetailExtraInfo] = []

        // Recipient info
        result.append(
            .init(
                title: L10n.sendTo,
                values: [
                    .init(text: RecipientFormatter.format(destination: userAction.recipient)),
                ],
                copyableValue: userAction.recipient
            )
        )

        let cryptoFormatter = CryptoFormatter()
        let currencyFormatter = CurrencyFormatter()

        if let arbiterFee = userAction.fees.arbiter {
            result.append(
                .init(
                    title: L10n.transactionFee,
                    values: [
                        .init(
                            text: cryptoFormatter.string(amount: arbiterFee),
                            secondaryText: currencyFormatter.string(amount: arbiterFee)
                        ),
                    ]
                )
            )
        }

        return result
    }

    var actions: [TransactionDetailAction] {
        switch status {
        case .succeed:
            if userAction.solanaTransaction != nil {
                return [
                    .share,
                    .explorer,
                ]
            } else {
                return []
            }
        default:
            return []
        }
    }

    var buttonTitle: String {
        L10n.done
    }

    var url: String? {
        if let solanaTransaction = userAction.solanaTransaction {
            return "https://explorer.solana.com/tx/\(solanaTransaction)"
        } else {
            return nil
        }
    }
}
