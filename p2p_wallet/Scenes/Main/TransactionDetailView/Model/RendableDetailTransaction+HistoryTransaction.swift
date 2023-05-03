//
//  RendableDetailTransaction+HistoryTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Combine
import Foundation
import History
import SolanaSwift

struct RendableDetailHistoryTransaction: RenderableTransactionDetail {
    let trx: HistoryTransaction

    let allTokens: Set<SolanaSwift.Token>

    var status: TransactionDetailStatus {
        switch trx.status {
        case .success:
            return .succeed(message: "")
        case .failed:
            if let error = trx.error?.description {
                return .error(message: NSAttributedString(string: error), error: nil)
            } else {
                return .error(message: NSAttributedString(string: L10n.theTransactionHasBeenRejected), error: nil)
            }
        }
    }

    var title: String {
        switch trx.status {
        case .success:
            return L10n.transactionSucceeded
        case .failed:
            return L10n.transactionFailed
        }
    }

    var subtitle: String {
        trx.date.string(withFormat: "MMMM dd, yyyy @ HH:mm", locale: Locale.base)
    }

    var signature: String? {
        trx.signature
    }

    var icon: TransactionDetailIcon {
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
        case .unknown, .none:
            return .icon(.planet)
        }
    }

    var amountInFiat: TransactionDetailChange {
        switch trx.info {
        case let .send(data):
            return .negative("-\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .receive(data):
            return .positive("+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .swap(data):
            return .unchanged("\(data.to.amount.usdAmount.fiatAmountFormattedString())")
        case let .burn(data):
            return .negative("-\((-data.amount.usdAmount).fiatAmountFormattedString())")
        case let .mint(data):
            return .positive("+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .stake(data):
            return .negative("-\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .unstake(data):
            return .positive("+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .createAccount(data):
            return .positive("+\(data.amount.usdAmount.fiatAmountFormattedString())")
        case let .closeAccount(data):
            if let data {
                return .negative("-\(data.amount.usdAmount.fiatAmountFormattedString())")
            } else {
                return .unchanged("")
            }
        case let .unknown(data):
            if data.amount.usdAmount >= 0 {
                return .positive("+\(data.amount.usdAmount.fiatAmountFormattedString())")
            } else {
                return .negative("\(data.amount.usdAmount.fiatAmountFormattedString())")
            }
        case .none:
            return .unchanged("")
        }
    }

    var amountInToken: String {
        switch trx.info {
        case let .send(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .receive(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .swap(data):
            return "\((-data.from.amount.tokenAmount).tokenAmountFormattedString(symbol: data.from.token.symbol)) → \(data.to.amount.tokenAmount.tokenAmountFormattedString(symbol: data.to.token.symbol))"
        case let .burn(data):
            return "\((-data.amount.tokenAmount).tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .mint(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .stake(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .unstake(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .createAccount(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case let .closeAccount(data):
            if let data {
                return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
            } else {
                return ""
            }
        case let .unknown(data):
            return "\(data.amount.tokenAmount.tokenAmountFormattedString(symbol: data.token.symbol))"
        case .none:
            return ""
        }
    }

    var extra: [TransactionDetailExtraInfo] {
        var result: [TransactionDetailExtraInfo] = []

        switch trx.info {
        case let .send(data):
            result.append(
                .init(
                    title: L10n.sendTo,
                    values: [
                        .init(text: data.account.name ?? RecipientFormatter.format(destination: data.account.address)),
                    ],
                    copyableValue: data.account.name ?? data.account.address
                )
            )
        case let .receive(data):
            result.append(
                .init(
                    title: L10n.receivedFrom,
                    values: [
                        .init(text: data.account.name ?? RecipientFormatter.format(destination: data.account.address)),
                    ],
                    copyableValue: data.account.name ?? data.account.address
                )
            )
        case .burn:
            result.append(
                .init(
                    title: L10n.burnSignature,
                    values: [.init(text: RecipientFormatter.signature(signature: trx.signature))]
                )
            )
        case .mint:
            result.append(
                .init(
                    title: L10n.mintSignature,
                    values: [.init(text: RecipientFormatter.signature(signature: trx.signature))]
                )
            )
        case .stake:
            result.append(
                .init(
                    title: L10n.stakeSignature,
                    values: [.init(text: RecipientFormatter.signature(signature: trx.signature))]
                )
            )
        case .unstake:
            result.append(
                .init(
                    title: L10n.unstakeSignature,
                    values: [.init(text: RecipientFormatter.signature(signature: trx.signature))]
                )
            )
        case .swap:
            break

        default:
            result.append(
                .init(
                    title: L10n.signature,
                    values: [.init(text: RecipientFormatter.signature(signature: trx.signature))]
                )
            )
        }

        if trx.fees.allSatisfy({ fee in Constants.feeRelayerAccounts.contains(fee.payer) }) {
            result.append(
                .init(
                    title: L10n.transactionFee,
                    values: [.init(text: L10n.freePaidByKeyApp)]
                )
            )
        } else {
            let values: [TransactionDetailExtraInfo.Value] = trx.fees.map { fee in
                .init(
                    text: fee.amount.tokenAmount.tokenAmountFormattedString(symbol: fee.token.symbol),
                    secondaryText: fee.amount.usdAmount.fiatAmountFormattedString()
                )
            }

            result.append(
                .init(
                    title: L10n.transactionFee,
                    values: values
                )
            )
        }
        return result
    }

    var actions: [TransactionDetailAction] = [.share, .explorer]

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

    private func icon(mint: String?, url: URL?, defaultIcon: UIImage) -> TransactionDetailIcon {
        if let url = resolveTokenIconURL(mint: mint, fallbackImageURL: url) {
            return .single(url)
        } else {
            return .icon(defaultIcon)
        }
    }

    var buttonTitle: String {
        switch trx.info {
        case .swap:
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

private enum Constants {
    static let swapFeeRelayerAccount = "JdYkwaUrvoeYsCbPgnt3AAa1qzjV2CtoRqU3bzuAvQu"
    static let feeRelayerAccount = "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT"

    static var feeRelayerAccounts = [Constants.swapFeeRelayerAccount, Constants.feeRelayerAccount]
}
