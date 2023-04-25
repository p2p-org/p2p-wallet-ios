import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

protocol WormholeClaimModel {
    var icon: URL? { get }

    var title: String { get }

    var subtitle: String { get }

    var claimButtonTitle: String { get }

    var claimButtonEnable: Bool { get }

    var fees: String { get }

    var feesButtonEnable: Bool { get }
    
    var isLoading: Bool { get }
}

struct WormholeClaimMockModel: WormholeClaimModel {
    var icon: URL?

    var title: String

    var subtitle: String

    var claimButtonTitle: String

    var claimButtonEnable: Bool

    var fees: String

    var feesButtonEnable: Bool
    
    var isLoading: Bool
}

struct WormholeClaimEthereumModel: WormholeClaimModel {
    let account: EthereumAccount
    let bundle: AsyncValueState<WormholeBundle?>

    var icon: URL? {
        account.token.logo
    }

    var title: String {
        let token = account.representedBalance.token
        return CryptoFormatterFactory.formatter(with: token, style: .short)
            .string(for: account.representedBalance)
            ?? "0 \(account.token.symbol)"
    }

    var subtitle: String {
        guard let currencyAmount = account.balanceInFiat else {
            return ""
        }

        let formattedValue = CurrencyFormatter().string(amount: currencyAmount)
        return "~ \(formattedValue)"
    }

    var claimButtonTitle: String {
        let resultAmount = bundle.value?.resultAmount

        if let resultAmount = resultAmount {
            let cryptoFormatter = CryptoFormatter()

            let cryptoAmount = CryptoAmount(
                bigUIntString: resultAmount.amount,
                token: account.token
            )

            return L10n.claim(cryptoFormatter.string(amount: cryptoAmount))
        } else {
            if bundle.error != nil {
                return L10n.claim
            } else {
                return L10n.loading
            }
        }
    }

    var claimButtonEnable: Bool {
        switch bundle.status {
        case .fetching, .initializing:
            return false
        case .ready:
            return true
        }
    }

    var fees: String {
        let bundle = bundle.value

        guard let bundle else {
            return L10n.isUnavailable(L10n.value)
        }

        if bundle.compensationDeclineReason == nil {
            return L10n.paidByKeyApp
        }

        return CurrencyFormatter().string(amount: bundle.fees.totalInFiat)
    }

    var feesButtonEnable: Bool {
        bundle.value?.fees != nil
    }
    
    var isLoading: Bool {
        bundle.isFetching
    }
}
