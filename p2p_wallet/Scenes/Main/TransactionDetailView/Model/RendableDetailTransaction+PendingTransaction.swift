//
//  RendableDetailTransaction+PendingTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Combine
import Foundation
import KeyAppKitCore
import SolanaPricesAPIs
import Wormhole

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

//        case let transaction as WormholeClaimTransaction:
//            guard let url = transaction.token.logo else {
//                return .icon(.planet)
//            }
//
//            return .single(url)
//
//        case let transaction as WormholeSendTransaction:
//            if
//                let urlStr = transaction.account.data.token.logoURI,
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
            if let price = priceService.currentPrice(mint: transaction.sourceWallet.token.address)?.value {
                let amountInFiat: Double = transaction.fromAmount * price
                return .unchanged("\(amountInFiat.fiatAmountFormattedString())")
            } else {
                return .unchanged("")
            }
        case let transaction as ClaimSentViaLinkTransaction:
            return .positive("+\(transaction.amountInFiat?.fiatAmountFormattedString() ?? "")")

//        case let transaction as WormholeClaimTransaction:
//            if let value = CurrencyFormatter().string(for: transaction.bundle.resultAmount) {
//                return .positive("+\(value)")
//            } else {
//                return .unchanged("")
//            }
//
//        case let transaction as WormholeSendTransaction:
//            let value = CurrencyFormatter().string(amount: transaction.currencyAmount)
//            return .negative(value)

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

                let feeAmountInFiat: Double = feeAmount * priceService
                    .currentPrice(mint: payingFeeWallet.token.address)?.value
                let formattedFeeAmountInFiat: String = feeAmountInFiat.fiatAmountFormattedString()

                result
                    .append(
                        .init(
                            title: L10n.transactionFee,
                            values: [.init(text: "\(formatedFeeAmount) (\(formattedFeeAmountInFiat))")]
                        )
                    )
            }

//        case let transaction as WormholeClaimTransaction:
//            if transaction.bundle.compensationDeclineReason == nil {
//                result.append(
//                    .init(
//                        title: L10n.transactionFee,
//                        values: [.init(text: L10n.freePaidByKeyApp)]
//                    )
//                )
//            } else {
//                // Collect all fees.
//                let allFees: [Wormhole.TokenAmount] = [
//                    transaction.bundle.fees.createAccount,
//                    transaction.bundle.fees.arbiter,
//                    transaction.bundle.fees.gas,
//                ].compactMap { $0 }
//
//                // Split into group token.
//                let compactFees = Dictionary(grouping: allFees) { fee in fee.token }
//
//                // Reduce into single amount in crypto and fiat.
//                let summarizedFees: [(CryptoAmount, CurrencyAmount)] = compactFees.mapValues { fees in
//                    guard
//                        let initialCryptoAmount = fees.first?.asCryptoAmount.with(amount: 0),
//                        let initialCurrencyAmount = fees.first?.asCurrencyAmount.with(amount: 0)
//                    else {
//                        return nil
//                    }
//
//                    let cryptoAmount = fees.map(\.asCryptoAmount).reduce(initialCryptoAmount, +)
//                    let fiatAmount = fees.map(\.asCurrencyAmount).reduce(initialCurrencyAmount,+)
//
//                    return (cryptoAmount, fiatAmount)
//                }
//                .values
//                .compactMap { $0 }
//
//                let cryptoFormatter = CryptoFormatter()
//                let currencyFormatter = CurrencyFormatter()
//
//                let formattedSummarizedFees: [TransactionDetailExtraInfo.Value] = summarizedFees
//                    .map { cryptoAmount, currencyAmount in
//                        let formattedCryptoAmount = cryptoFormatter.string(for: cryptoAmount)
//                        let formattedCurrencyFormatter = currencyFormatter.string(for: currencyAmount)
//
//                        return TransactionDetailExtraInfo.Value(
//                            text: formattedCryptoAmount ?? "",
//                            secondaryText: formattedCurrencyFormatter ?? ""
//                        )
//                    }
//
//                result.append(
//                    .init(
//                        title: L10n.transferFee,
//                        values: formattedSummarizedFees
//                    )
//                )
//            }
//
//        case let transaction as WormholeSendTransaction:
//            result.append(
//                .init(
//                    title: L10n.sendTo,
//                    values: [
//                        .init(
//                            text: RecipientFormatter.format(destination: transaction.recipient.address)
//                        ),
//                    ]
//                )
//            )
//
//            // Collect all fees.
//            let allFees: [Wormhole.TokenAmount] = [
//                transaction.fees.arbiter,
//                transaction.fees.networkFee,
//                transaction.fees.bridgeFee,
//                transaction.fees.messageAccountRent,
//            ].compactMap { $0 }
//
//            // Split into group token.
//            let compactFees = Dictionary(grouping: allFees) { fee in fee.token }
//
//            // Reduce into single amount in crypto and fiat.
//            let summarizedFees: [(CryptoAmount, CurrencyAmount)] = compactFees
//                .mapValues { fees -> (CryptoAmount, CurrencyAmount)? in
//                    guard
//                        let initialCryptoAmount = fees.first?.asCryptoAmount.with(amount: 0),
//                        let initialCurrencyAmount = fees.first?.asCurrencyAmount.with(amount: 0)
//                    else {
//                        return nil
//                    }
//
//                    let cryptoAmount = fees.map(\.asCryptoAmount).reduce(initialCryptoAmount, +)
//                    let fiatAmount = fees.map(\.asCurrencyAmount).reduce(initialCurrencyAmount,+)
//
//                    return (cryptoAmount, fiatAmount)
//                }
//                .values
//                .compactMap { $0 }
//
//            let cryptoFormatter = CryptoFormatter()
//            let currencyFormatter = CurrencyFormatter()
//
//            let formattedSummarizedFees: [TransactionDetailExtraInfo.Value] = summarizedFees
//                .map { cryptoAmount, currencyAmount in
//                    let formattedCryptoAmount = cryptoFormatter.string(for: cryptoAmount)
//                    let formattedCurrencyFormatter = currencyFormatter.string(for: currencyAmount)
//
//                    return TransactionDetailExtraInfo.Value(
//                        text: formattedCryptoAmount ?? "",
//                        secondaryText: formattedCurrencyFormatter ?? ""
//                    )
//                }
//
//            result.append(
//                .init(
//                    title: L10n.transferFee,
//                    values: formattedSummarizedFees
//                )
//            )

        case let transaction as ClaimSentViaLinkTransaction:
            result.append(
                .init(
                    title: L10n.receivedFrom,
                    values: [.init(text: transaction.claimableTokenInfo.account)],
                    copyableValue: transaction.claimableTokenInfo.account
                )
            )

            result.append(
                .init(
                    title: L10n.transactionFee,
                    values: [.init(text: L10n.freePaidByKeyApp)]
                )
            )

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

    var buttonTitle: String {
        switch trx.rawTransaction {
        case _ as SwapRawTransactionType:
            switch status {
            case let .error(_, error):
                if let error, error.isSlippageError {
                    return L10n.increaseSlippageAndTryAgain
                } else {
                    return L10n.tryAgain
                }
            default:
                return L10n.done
            }

        default:
            return L10n.done
        }
    }
}

extension Error {
    var isSlippageError: Bool {
        readableDescription.contains("Slippage tolerance exceeded")
    }
}
