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
    let cryptoFormatter: CryptoFormatter = .init()
    let currencyFormatter: CurrencyFormatter = .init()

    let state: WormholeSendInputState

    var input: WormholeSendInputBase? {
        switch state {
        case let .ready(input, output, alert):
            return input
        case let .calculating(newInput):
            return newInput
        case let .error(input, output, error):
            return input
        case .initializingFailure:
            return nil
        }
    }

    var output: WormholeSendOutputBase? {
        switch state {
        case let .ready(input, output, alert):
            return output
        case let .calculating(newInput):
            return nil
        case let .error(input, output, error):
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
        case let .ready(input, output, alert):
            return "Fees: \(currencyFormatter.string(amount: output.fees.totalInFiat))"
        case let .calculating(newInput):
            return ""
        case let .error(input, output, error):
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
        case let .ready(input, output, alert):
            return false
        case let .calculating(newInput):
            return true
        case let .error(input, output, error):
            return false
        case .initializingFailure:
            return false
        }
    }

    var inputColor: UIColor {
        switch state {
        case let .error(input, output, error) where error == .maxAmountReached:
            return Asset.Colors.rose.color
        default:
            return Asset.Colors.night.color
        }
    }

    var sliderButton: SliderActionButtonData {
        switch state {
        case let .error(input, output, error):
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
                text = L10n.insufficientFunds
            case .invalidBaseFeeToken, .missingRelayContext:
                text = L10n.internalError
            }

            return .init(isEnabled: false, title: text)
        case let .ready(input, _, _):
            if input.amount.value == 0 {
                return .init(isEnabled: false, title: L10n.insufficientFunds)
            } else {
                return .init(isEnabled: true, title: "\(L10n.send) \(cryptoFormatter.string(amount: input.amount))")
            }
        default:
            return .init(isEnabled: false, title: L10n.calculatingTheFees)
        }
    }

    var disableSwitch: Bool {
        input?.solanaAccount.price == nil
    }
}
