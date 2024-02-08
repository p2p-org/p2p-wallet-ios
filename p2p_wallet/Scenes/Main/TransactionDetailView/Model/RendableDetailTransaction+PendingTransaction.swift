import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

struct RendableDetailPendingTransaction: RenderableTransactionDetail {
    let trx: PendingTransaction

    var status: TransactionDetailStatus {
        if trx.transactionId != nil, !(trx.rawTransaction is ClaimSentViaLinkTransaction) {
            return .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted)
        }

        switch trx.status {
        case let .error(errorModel):
            if errorModel.isSlippageError {
                return .error(message: NSAttributedString(string: errorModel.readableDescription), error: errorModel)
            }
            return .error(message: NSAttributedString(
                string: L10n.OopsSomethingWentWrong.pleaseTryAgainLater
            ), error: errorModel)
        case .finalized:
            return .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted)
        default:
            return .loading(message: L10n.theTransactionWillBeCompletedInAFewSeconds)
        }
    }

    var title: String {
        if trx.transactionId != nil, !(trx.rawTransaction is ClaimSentViaLinkTransaction) {
            return L10n.transactionSucceeded
        }

        switch trx.status {
        case .error:
            return L10n.transactionFailed
        case .finalized:
            return L10n.transactionSucceeded
        default:
            return L10n.transactionSubmitted
        }
    }

    var subtitle: String {
        if trx.rawTransaction is ClaimSentViaLinkTransaction {
            switch trx.status {
            case .error, .finalized:
                break
            default:
                return L10n.pending.capitalized
            }
        }
        return trx.sentAt.string(withFormat: "MMMM dd, yyyy @ HH:mm", locale: Locale.base)
    }

    var signature: String? {
        trx.transactionId
    }

    var icon: TransactionDetailIcon {
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
        case let transaction as ClaimSentViaLinkTransaction:
            if
                let urlStr = transaction.token.logoURI,
                let url = URL(string: urlStr)
            {
                return .single(url)
            } else {
                return .icon(.transactionReceive)
            }

//        case let transaction as WormholeClaimTransaction:
//            guard let url = transaction.token.logo else {
//                return .icon(.planet)
//            }
//
//            return .single(url)
//
//        case let transaction as WormholeSendTransaction:
//            if
//                let urlStr = transaction.account.token.logoURI,
//                let url = URL(string: urlStr)
//            {
//                return .single(url)
//            } else {
//                return .icon(.transactionSend)
//            }
        default:
            return .icon(.planet)
        }
    }

    var amountInFiat: TransactionDetailChange {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            if transaction.amountInFiat == 0.0 {
                return .negative(
                    "\(transaction.amount.tokenAmountFormattedString(symbol: transaction.walletToken.token.symbol))"
                )
            } else {
                return .negative("-\(transaction.amountInFiat.fiatAmountFormattedString())")
            }

        case let transaction as SwapRawTransactionType:
            if let price = transaction.sourceWallet.price?.doubleValue {
                let amountInFiat: Double = transaction.fromAmount * price
                return .unchanged("\(amountInFiat.fiatAmountFormattedString())")
            } else {
                return .unchanged("")
            }
        case let transaction as ClaimSentViaLinkTransaction:
            if let amountInFiat = transaction.amountInFiat?.fiatAmountFormattedString() {
                return .positive("+\(amountInFiat)")
            }
            return .unchanged("")

        default:
            return .unchanged("")
        }
    }

    var amountInToken: String {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            if transaction.amountInFiat == 0.0 {
                return ""
            } else {
                return "\(transaction.amount.tokenAmountFormattedString(symbol: transaction.walletToken.token.symbol))"
            }

        case let transaction as SwapRawTransactionType:
            return transaction.mainDescription

//        case let transaction as WormholeClaimTransaction:
//            guard let value = CryptoFormatter().string(for: transaction.bundle.resultAmount) else {
//                return ""
//            }
//            return "\(value)"
//
//        case let transaction as WormholeSendTransaction:
//            let value = CryptoFormatter().string(amount: transaction.amount)
//            return "\(value)"

        case let transaction as SwapRawTransactionType:
            return transaction.mainDescription

        case let transaction as ClaimSentViaLinkTransaction:
            return "\(transaction.tokenAmount.tokenAmountFormattedString(symbol: transaction.token.symbol))"

        default:
            return ""
        }
    }

    var extra: [TransactionDetailExtraInfo] {
        var result: [TransactionDetailExtraInfo] = []

        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            switch transaction.recipient.category {
            case let .username(name, domain):
                result.append(
                    .init(
                        title: L10n.sendTo,
                        values: [.init(text: RecipientFormatter.username(name: name, domain: domain))],
                        copyableValue: "\(name).\(domain)"
                    )
                )
            case let .solanaTokenAddress(walletAddress, _):
                result.append(
                    .init(
                        title: L10n.sendTo,
                        values: [
                            .init(text: RecipientFormatter.format(destination: walletAddress.base58EncodedString)),
                        ],
                        copyableValue: walletAddress.base58EncodedString
                    )
                )
            case .solanaAddress:
                result.append(
                    .init(
                        title: L10n.sendTo,
                        values: [
                            .init(text: RecipientFormatter.format(destination: transaction.recipient.address)),
                        ],
                        copyableValue: transaction.recipient.address
                    )
                )
            default:
                break
            }

            if transaction.feeAmount.total == 0 {
                result.append(
                    .init(
                        title: L10n.transactionFee,
                        values: [.init(text: L10n.freePaidByKeyApp)]
                    )
                )
            } else {
                let feeAmount: Double = transaction.feeAmount.total
                    .convertToBalance(decimals: transaction.payingFeeWallet?.token.decimals)
                let formatedFeeAmount: String = feeAmount
                    .tokenAmountFormattedString(symbol: transaction.payingFeeWallet?.token.symbol ?? "")
                result.append(
                    .init(
                        title: L10n.transactionFee,
                        values: [.init(text: formatedFeeAmount)]
                    )
                )
            }
        case let transaction as SwapRawTransactionType:
            let fees = transaction.feeAmount

            if fees.total == 0 {
                result.append(
                    .init(
                        title: L10n.transactionFee,
                        values: [.init(text: L10n.freePaidByKeyApp)]
                    )
                )
            }

            // network fee
            else if let payingFeeWallet = transaction.payingFeeWallet {
                let feeAmount: Double = fees.total.convertToBalance(decimals: payingFeeWallet.token.decimals)
                let formatedFeeAmount: String = feeAmount
                    .tokenAmountFormattedString(symbol: payingFeeWallet.token.symbol)

                let feeAmountInFiat: Double = feeAmount * payingFeeWallet.price?.doubleValue
                let formattedFeeAmountInFiat: String = feeAmountInFiat.fiatAmountFormattedString()

                result
                    .append(
                        .init(
                            title: L10n.transactionFee,
                            values: [.init(text: "\(formatedFeeAmount) (\(formattedFeeAmountInFiat))")]
                        )
                    )
            }

        case let transaction as ClaimSentViaLinkTransaction:
            let title: String
            switch trx.status {
            case .error, .finalized:
                title = L10n.receivedFrom
            default:
                title = L10n.from
            }
            result.append(
                .init(
                    title: title,
                    values: [
                        .init(text: RecipientFormatter
                            .format(destination: transaction.claimableTokenInfo.keypair.publicKey
                                .base58EncodedString)),
                    ],
                    copyableValue: transaction.claimableTokenInfo.account
                )
            )
            result.append(.init(title: L10n.transactionFee, values: [.init(text: L10n.freePaidByKeyApp)]))
        default:
            break
        }

        return result
    }

    var actions: [TransactionDetailAction] {
        switch trx.status {
        case .finalized:
            return [.share, .explorer]
        default:
            return []
        }
    }

    var bottomActions: [TransactionBottomAction] {
        switch trx.rawTransaction {
        case _ as SwapRawTransactionType:
            switch status {
            case let .error(_, error):
                if let error, error.isSlippageError {
                    return [.increaseSlippageAndTryAgain]
                } else {
                    return [.tryAgain]
                }
            default:
                return [.done]
            }

        default:
            return [.done]
        }
    }

    var url: String? {
        "https://solscan.io/tx/\(signature ?? "")"
    }
}

extension Error {
    var isSlippageError: Bool {
        readableDescription.contains("Slippage tolerance exceeded")
    }
}
