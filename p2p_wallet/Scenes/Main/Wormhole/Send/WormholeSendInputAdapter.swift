//
//  WormholeSendInputAdapter.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeyAppUI
import Send
import Wormhole

struct WormholeSendInputStateAdapter: Equatable {
    let cryptoFormatter = CryptoFormatter()
    let currencyFormatter = CurrencyFormatter()

    let state: WormholeSendInputState

    var input: WormholeSendInputBase? {
        switch state {
        case let .ready(input, _, _):
            return input
        case let .calculating(newInput):
            return newInput
        case let .error(input, _, _):
            return input
        case .initializingFailure:
            return nil
        }
    }

    var output: WormholeSendOutputBase? {
        switch state {
        case let .ready(_, output, _):
            return output
        case .calculating:
            return nil
        case let .error(_, output, _):
            return output
        case .initializingFailure:
            return nil
        }
    }

    var inputAccount: SolanaAccountsService.Account? {
        input?.solanaAccount
    }

    var selectedToken: SolanaToken {
        inputAccount?.data.token ?? .nativeSolana
    }

    var inputAccountSkeleton: Bool {
        inputAccount == nil
    }

    var cryptoAmount: CryptoAmount {
        guard let input = input else {
            return .init(amount: 0, token: SolanaToken.nativeSolana)
        }

        return input.amount
    }

    var cryptoAmountString: String {
        cryptoFormatter.string(amount: cryptoAmount)
    }

    // Fiat symbol
    var fiatString: String {
        Defaults.fiat.code
    }

    var amountInFiatString: String {
        guard
            let price = input?.solanaAccount.price,
            let currencyAmount = try? cryptoAmount.toFiatAmount(price: price)
        else { return "" }

        return currencyFormatter.string(amount: currencyAmount)
    }

    var fees: String {
        switch state {
        case let .ready(_, output, _):
            return "Fees: \(currencyFormatter.string(amount: output.fees.totalInFiat))"
        case .calculating:
            return ""
        case let .error(_, output, _):
            if let output {
                return "Fees: \(currencyFormatter.string(amount: output.fees.totalInFiat))"
            } else {
                return ""
            }
        case .initializingFailure:
            return ""
        }
    }

    var feesLoading: Bool {
        switch state {
        case .ready:
            return false
        case .calculating:
            return true
        case .error:
            return false
        case .initializingFailure:
            return false
        }
    }

    var inputColor: UIColor {
        switch state {
        case let .error(_, _, error) where error == .maxAmountReached:
            return Asset.Colors.rose.color
        default:
            return Asset.Colors.night.color
        }
    }

    var sliderButton: SliderActionButtonData {
        switch state {
        case let .error(input, _, error):
            let text: String
            switch error {
            case .maxAmountReached:
                text = L10n.max(cryptoFormatter.string(amount: input.solanaAccount.cryptoAmount))
            case .calculationFeeFailure, .calculationFeePayerFailure:
                text = L10n.CannotCalculateFees.tryAgain
            case .getTransferTransactionsFailure:
                text = L10n.creatingTransactionFailed
            case .initializationFailure:
                text = L10n.initializingError
            case .insufficientInputAmount:
                if input.amount.value == 0 {
                    text = L10n.enterAmount
                } else {
                    text = L10n.insufficientFunds
                }
            case .invalidBaseFeeToken, .missingRelayContext:
                text = L10n.internalError
            case .feeIsMoreThanInputAmount:
                text = L10n.theFeeIsMoreThanTheAmountSent
            }

            return .init(isEnabled: false, title: text)
        case let .ready(input, output, _):
            if input.amount.value == 0 {
                return .init(isEnabled: false, title: L10n.insufficientFunds)
            } else {
                guard let resultAmount = output.fees.resultAmount else {
                    return .init(isEnabled: false, title: L10n.internalError)
                }

                return .init(
                    isEnabled: true,
                    title: "\(L10n.send) \(cryptoFormatter.string(amount: resultAmount))"
                )
            }
        default:
            return .init(isEnabled: false, title: L10n.calculatingTheFees)
        }
    }

    var disableSwitch: Bool {
        input?.solanaAccount.price == nil
    }
}
