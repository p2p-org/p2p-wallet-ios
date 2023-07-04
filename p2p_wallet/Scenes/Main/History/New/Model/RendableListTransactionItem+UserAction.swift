import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send
import SolanaSwift
import Wormhole

struct RendableListUserActionTransactionItem: RendableListTransactionItem {
    let userAction: any UserAction

    var onTap: (() -> Void)?

    var id: String {
        userAction.id
    }

    var date: Date {
        userAction.createdDate
    }

    var status: RendableListTransactionItemStatus {
        switch userAction.status {
        case .pending, .processing:
            return .pending
        case .ready:
            return .success
        case .error:
            return .failed
        }
    }

    var icon: RendableListTransactionItemIcon {
        switch userAction {
        case let userAction as WormholeClaimUserAction:
            guard let url = userAction.token.logo else {
                return .icon(.planet)
            }

            return .single(url)

        case let userAction as WormholeSendUserAction:
            if
                let urlStr = userAction.sourceToken.logoURI,
                let url = URL(string: urlStr)
            {
                return .single(url)
            } else {
                return .icon(.transactionSend)
            }
        default:
            return .icon(.planet)
        }
    }

    var title: String {
        switch userAction {
        case let transaction as WormholeClaimUserAction:
            return "\(L10n.from.uppercaseFirst) Ethereum"

        case let transaction as WormholeSendUserAction:
            return "\(L10n.to.uppercaseFirst) Ethereum"

        default:
            return "Unknown"
        }
    }

    var subtitle: String {
        switch userAction {
        case is WormholeClaimUserAction:
            switch status {
            case .success:
                return L10n.receive
            case .pending:
                return L10n.claiming
            case .failed:
                return L10n.receive
            }

        case is WormholeSendUserAction:
            switch status {
            case .success:
                return L10n.send
            case .pending:
                return L10n.sending
            case .failed:
                return L10n.send
            }

        default:
            return "Unknown"
        }
    }

    var detail: (RendableListTransactionItemChange, String) {
        switch userAction {
        case let transaction as WormholeSendUserAction:
            if let currencyAmount = transaction.currencyAmount {
                let amount = CurrencyFormatter().string(amount: currencyAmount)
                return (.negative, "-\(amount)")
            } else {
                return (.unchanged, "")
            }

        case let transaction as WormholeClaimUserAction:
            if let currencyAmount = transaction.amountInFiat {
                let amount = CurrencyFormatter().string(amount: currencyAmount)
                return (.positive, "+\(amount)")
            } else {
                return (.unchanged, "")
            }

        default:
            return (.unchanged, "")
        }
    }

    var subdetail: String {
        switch userAction {
        case let transaction as WormholeSendUserAction:
            return CryptoFormatter().string(amount: transaction.amount)

        case let transaction as WormholeClaimUserAction:
            return CryptoFormatter().string(amount: transaction.amountInCrypto)

        default:
            return ""
        }
    }
}
