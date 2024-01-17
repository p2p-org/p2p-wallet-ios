import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Send
import UIKit
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

    var inputAccountSkeleton: Bool {
        inputAccount == nil
    }

    // Fiat symbol
    var fiatString: String {
        Defaults.fiat.code
    }

    var fees: String {
        switch state {
        case let .ready(_, output, _):
            if let arbiter = output.fees.arbiter?.asCryptoAmount {
                return "≈\(cryptoFormatter.string(amount: arbiter))"
            } else {
                return ""
            }
        case let .error(_, output, _):
            if let output, let arbiter = output.fees.arbiter?.asCryptoAmount {
                return "≈\(cryptoFormatter.string(amount: arbiter))"
            } else {
                return ""
            }
        case .initializingFailure, .calculating:
            return ""
        }
    }

    var isFeeGTAverage: Bool {
        switch state {
        case let .ready(_, output, _):
            return (output.fees.arbiter?.asCurrencyAmount.value ?? 0) > 30
        case let .error(_, output, _):
            if let output {
                return (output.fees.arbiter?.asCurrencyAmount.value ?? 0) > 30
            } else {
                return false
            }
        case .initializingFailure, .calculating:
            return false
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

    var inputColor: ColorResource {
        switch state {
        case let .error(input, output, error) where error == .maxAmountReached:
            return .rose
        default:
            return .night
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
                if input.amount.value == 0 {
                    text = L10n.enterAmount
                } else {
                    text = L10n.checkAvailableFunds
                }
            case .invalidBaseFeeToken, .missingRelayContext:
                text = L10n.internalError
            case .feeIsMoreThanInputAmount:
                text = L10n.theFeeIsMoreThanTheAmountSent
            }

            return .init(isEnabled: false, title: text)
        case let .ready(input, _, _):
            if input.amount.value == 0 {
                return .init(isEnabled: false, title: L10n.enterAmount)
            } else {
                return .init(isEnabled: true, title: L10n.send)
            }
        default:
            return .init(isEnabled: false, title: L10n.calculatingTheFees)
        }
    }

    var disableSwitch: Bool {
        true
    }

    var totalCryptoAmount: String {
        if let input {
            let totalAmount = output?.fees.totalAmount?.asCryptoAmount ?? input.amount.with(amount: 0)
            return cryptoFormatter.string(amount: totalAmount)
        } else {
            return "N/A"
        }
    }

    var totalCurrencyAmount: String {
        if let input {
            if let price = input.solanaAccount.price {
                let arbiterFee = output?.fees.arbiter?.asCurrencyAmount ?? .zero
                let inputAmountInFiat = try? input.amount.toFiatAmount(price: price)
                if let inputAmountInFiat {
                    return currencyFormatter.string(amount: inputAmountInFiat + arbiterFee)
                } else {
                    return "N/A"
                }
            } else {
                let arbiterFee = output?.fees.arbiter?.asCryptoAmount ?? input.amount.with(amount: 0)
                return cryptoFormatter.string(amount: input.amount + arbiterFee)
            }
        } else {
            return "N/A"
        }
    }

    var maxCurrencyAmount: CryptoAmount? {
        if let input, let output, let arbiterFee = output.fees.arbiter {
            guard input.solanaAccount.cryptoAmount > arbiterFee.asCryptoAmount else {
                return nil
            }
            return input.solanaAccount.cryptoAmount - arbiterFee.asCryptoAmount
        } else {
            return nil
        }
    }

    var maxFiatAmount: CurrencyAmount? {
        if let maxCurrencyAmount {
            return try? maxCurrencyAmount.toFiatAmountIfPresent(price: input?.solanaAccount.price)
        } else {
            return nil
        }
    }
}
