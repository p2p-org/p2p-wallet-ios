//
//  RendableDetailTransaction+PendingTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Combine
import Foundation
import SolanaPricesAPIs

struct RendableDetailPendingTransaction: RendableTransactionDetail {
    let trx: PendingTransaction

    let priceService: PricesService

    var status: TransactionDetailStatus {
        if trx.transactionId != nil {
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
            return .loading(message: L10n.itUsuallyTakes520SecondsForATransactionToComplete)
        }
    }

    var title: String {
        if trx.transactionId != nil {
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
        trx.sentAt.string(withFormat: "MMMM dd, yyyy @ HH:mm", locale: Locale.base)
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
            if let price = priceService.currentPrice(mint: transaction.sourceWallet.token.address)?.value {
                let amountInFiat: Double = transaction.fromAmount * price
                return .unchanged("\(amountInFiat.fiatAmountFormattedString())")
            } else {
                return .unchanged("")
            }
        case let transaction as ClaimSentViaLinkTransaction:
            return .positive("+\(transaction.amountInFiat?.fiatAmountFormattedString() ?? "")")

        default:
            return .unchanged("")
        }
    }

    var amountInToken: String {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            return "\(transaction.amount.tokenAmountFormattedString(symbol: transaction.walletToken.token.symbol))"
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
                        value: RecipientFormatter.username(name: name, domain: domain),
                        copyableValue: "\(name).\(domain)"
                    )
                )
            case let .solanaTokenAddress(walletAddress, _):
                result.append(
                    .init(
                        title: L10n.sendTo,
                        value: RecipientFormatter.format(destination: walletAddress.base58EncodedString),
                        copyableValue: walletAddress.base58EncodedString
                    )
                )
            case .solanaAddress:
                result.append(
                    .init(
                        title: L10n.sendTo,
                        value: RecipientFormatter.format(destination: transaction.recipient.address),
                        copyableValue: transaction.recipient.address
                    )
                )
            default:
                break
            }

            if transaction.feeAmount.total == 0 {
                result.append(.init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp))
            } else {
                let feeAmount: Double = transaction.feeAmount.total
                    .convertToBalance(decimals: transaction.payingFeeWallet?.token.decimals)
                let formatedFeeAmount: String = feeAmount
                    .tokenAmountFormattedString(symbol: transaction.payingFeeWallet?.token.symbol ?? "")
                result.append(.init(title: L10n.transactionFee, value: formatedFeeAmount))
            }
        case let transaction as SwapRawTransactionType:
            let fees = transaction.feeAmount

            if fees.total == 0 {
                result.append(.init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp))
            }

            // net work fee
            else if let payingFeeWallet = transaction.payingFeeWallet {
                let feeAmount: Double = fees.total.convertToBalance(decimals: payingFeeWallet.token.decimals)
                let formatedFeeAmount: String = feeAmount
                    .tokenAmountFormattedString(symbol: payingFeeWallet.token.symbol)

                let feeAmountInFiat: Double = feeAmount * priceService
                    .currentPrice(mint: payingFeeWallet.token.address)?.value
                let formattedFeeAmountInFiat: String = feeAmountInFiat.fiatAmountFormattedString()

                result
                    .append(.init(title: L10n.transactionFee,
                                  value: "\(formatedFeeAmount) (\(formattedFeeAmountInFiat))"))
            }
        case let transaction as ClaimSentViaLinkTransaction:
            result.append(
                .init(
                    title: L10n.receivedFrom,
                    value: RecipientFormatter.format(destination: transaction.claimableTokenInfo.account),
                    copyableValue: transaction.claimableTokenInfo.account
                )
            )
            
            result.append(.init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp))
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
}

extension Error {
    var isSlippageError: Bool {
        readableDescription.contains("Slippage tolerance exceeded")
    }
}
