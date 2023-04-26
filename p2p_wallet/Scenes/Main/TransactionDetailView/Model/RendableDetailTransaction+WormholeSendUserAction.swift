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

struct RendableWormholeSendUserActionDetail: RendableTransactionDetail {
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
            return .negative(value)
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
                ]
            )
        )

        // Collect all fees.
        let allFees: [Wormhole.TokenAmount] = [
            userAction.fees.arbiter,
            userAction.fees.networkFee,
            userAction.fees.bridgeFee,
            userAction.fees.messageAccountRent,
        ].compactMap { $0 }

        // Split into group token.
        let compactFees = Dictionary(grouping: allFees) { fee in fee.token }

        // Reduce into single amount in crypto and fiat.
        let summarizedFees: [(CryptoAmount, CurrencyAmount)] = compactFees
            .mapValues { fees -> (CryptoAmount, CurrencyAmount)? in
                guard
                    let initialCryptoAmount = fees.first?.asCryptoAmount.with(amount: 0),
                    let initialCurrencyAmount = fees.first?.asCurrencyAmount.with(amount: 0)
                else {
                    return nil
                }

                let cryptoAmount = fees.map(\.asCryptoAmount).reduce(initialCryptoAmount, +)
                let fiatAmount = fees.map(\.asCurrencyAmount).reduce(initialCurrencyAmount,+)

                return (cryptoAmount, fiatAmount)
            }
            .values
            .compactMap { $0 }

        let cryptoFormatter = CryptoFormatter()
        let currencyFormatter = CurrencyFormatter()

        let formattedSummarizedFees: [TransactionDetailExtraInfo.Value] = summarizedFees
            .sorted { rhs, lhs in
                rhs.0.value > lhs.0.value
            }
            .map { cryptoAmount, currencyAmount in
                let formattedCryptoAmount = cryptoFormatter.string(for: cryptoAmount)
                let formattedCurrencyFormatter = currencyFormatter.string(for: currencyAmount)

                return TransactionDetailExtraInfo.Value(
                    text: formattedCryptoAmount ?? "",
                    secondaryText: formattedCurrencyFormatter ?? ""
                )
            }

        result.append(
            .init(
                title: L10n.transferFee,
                values: formattedSummarizedFees
            )
        )

        return result
    }

    var actions: [TransactionDetailAction] {
        []
    }

    var buttonTitle: String {
        L10n.done
    }
}
