import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Send
import Wormhole

struct RenderableWormholeClaimUserActionDetail: RenderableTransactionDetail {
    let userAction: WormholeClaimUserAction

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
        guard let url = userAction.token.logo else {
            return .icon(.planet)
        }

        return .single(url)
    }

    var amountInFiat: TransactionDetailChange {
        if let value = CurrencyFormatter().string(for: userAction.amountInFiat) {
            return .positive("+\(value)")
        } else {
            return .unchanged("")
        }
    }

    var amountInToken: String {
        let value = CryptoFormatter().string(amount: userAction.amountInCrypto)
        return "\(value)"
    }

    var extra: [TransactionDetailExtraInfo] {
        var result: [TransactionDetailExtraInfo] = []

        if userAction.compensationDeclineReason == nil {
            result.append(
                .init(
                    title: L10n.transactionFee,
                    values: [.init(text: L10n.freePaidByKeyApp)]
                )
            )
        } else {
            // Collect all fees.
            let allFees: [Wormhole.TokenAmount] = [
                userAction.fees.createAccount,
                userAction.fees.arbiter,
                userAction.fees.gasInToken,
            ].compactMap { $0 }

            // Split into group token.
            let compactFees = Dictionary(grouping: allFees) { fee in fee.token }

            // Reduce into single amount in crypto and fiat.
            let summarizedFees: [(CryptoAmount, CurrencyAmount)] = compactFees.mapValues { fees in
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
        }

        return result
    }

    var actions: [TransactionDetailAction] {
        []
    }

    var buttonTitle: String {
        L10n.done
    }
}
