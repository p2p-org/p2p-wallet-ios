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

        case let .wormholeSend(data):
            return icon(mint: data.tokenAmount.token.mint, url: data.tokenAmount.token.logoUrl, defaultIcon: .planet)

        case let .wormholeReceive(data):
            return icon(mint: data.tokenAmount.token.mint, url: data.tokenAmount.token.logoUrl, defaultIcon: .planet)

        case .tryCreateAccount:
            return .icon(.planet)

        case .unknown, .none:
            return .icon(.planet)
        }
    }

    var amountInFiat: TransactionDetailChange {
        switch trx.info {
        case let .send(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .negative("-\(usdAmount.fiatAmountFormattedString())")

        case let .receive(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .positive("+\(usdAmount.fiatAmountFormattedString())")

        case let .swap(data):
            guard let usdAmount = data.to.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .unchanged("\(usdAmount.fiatAmountFormattedString())")

        case let .burn(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .negative("-\((-usdAmount).fiatAmountFormattedString())")

        case let .mint(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .positive("+\(usdAmount.fiatAmountFormattedString())")

        case let .stake(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .negative("-\(usdAmount.fiatAmountFormattedString())")

        case let .unstake(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .positive("+\(usdAmount.fiatAmountFormattedString())")

        case let .createAccount(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .positive("+\(usdAmount.fiatAmountFormattedString())")

        case let .closeAccount(data):
            if let data {
                guard let usdAmount = data.amount.usdAmountDouble else {
                    return .unchanged("")
                }
                return .negative("-\(usdAmount.fiatAmountFormattedString())")
            } else {
                return .unchanged("")
            }

        case let .unknown(data):
            guard let usdAmount = data.amount.usdAmountDouble else {
                return .unchanged("")
            }
            if usdAmount >= 0 {
                return .positive("+\(usdAmount.fiatAmountFormattedString())")
            } else {
                return .negative("\(usdAmount.fiatAmountFormattedString())")
            }

        case let .wormholeSend(data):
            guard let usdAmount = data.tokenAmount.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .negative("-\(usdAmount.fiatAmountFormattedString())")

        case let .wormholeReceive(data):
            guard let usdAmount = data.tokenAmount.amount.usdAmountDouble else {
                return .unchanged("")
            }
            return .positive("+\(usdAmount.fiatAmountFormattedString())")

        case .tryCreateAccount:
            return .unchanged("")

        case .none:
            return .unchanged("")
        }
    }

    var amountInToken: String {
        switch trx.info {
        case let .send(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .receive(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .swap(data):
            return "\((-data.from.amount.tokenAmountDouble).tokenAmountFormattedString(symbol: data.from.token.symbol)) → \(data.to.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.to.token.symbol))"

        case let .burn(data):
            return "\((-data.amount.tokenAmountDouble).tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .mint(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .stake(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .unstake(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .createAccount(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case let .closeAccount(data):
            if let data {
                return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"
            } else {
                return ""
            }

        case let .wormholeSend(data):
            return "-\(data.tokenAmount.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.tokenAmount.token.symbol))"

        case let .wormholeReceive(data):
            return "+\(data.tokenAmount.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.tokenAmount.token.symbol))"

        case let .unknown(data):
            return "\(data.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: data.token.symbol))"

        case .tryCreateAccount:
            return ""

        case .none:
            return ""
        }
    }

    var extra: [TransactionDetailExtraInfo] {
        var result: [TransactionDetailExtraInfo] = []

        switch trx.info {
        case let .send(data):
            let value: String
            if let name = data.account.name {
                value = "@\(name)"
            } else {
                value = RecipientFormatter.shortFormat(destination: data.account.address)
            }
            result.append(
                .init(
                    title: L10n.sendTo,
                    values: [
                        .init(text: value),
                    ],
                    copyableValue: data.account.name ?? data.account.address
                )
            )
        case let .receive(data):
            let value: String
            if let name = data.account.name {
                value = "@\(name)"
            } else {
                value = RecipientFormatter.shortFormat(destination: data.account.address)
            }
            result.append(
                .init(
                    title: L10n.receivedFrom,
                    values: [
                        .init(text: value),
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
                    text: fee.amount.tokenAmountDouble.tokenAmountFormattedString(symbol: fee.token.symbol),
                    secondaryText: fee.amount.usdAmountDouble?.fiatAmountFormattedString()
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

    var url: String? {
        "https://explorer.solana.com/tx/\(signature ?? "")"
    }
}

private enum Constants {
    static let swapFeeRelayerAccount = "JdYkwaUrvoeYsCbPgnt3AAa1qzjV2CtoRqU3bzuAvQu"
    static let feeRelayerAccount = "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT"

    static var feeRelayerAccounts = [Constants.swapFeeRelayerAccount, Constants.feeRelayerAccount]
}
