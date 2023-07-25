import BankTransfer
import BigInt
import BigDecimal
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Web3
import Wormhole

struct BankTransferRenderableAccount: RenderableAccount {
    let accountId: String
    let token: EthereumToken
    let visibleAmount: Int
    let rawAmount: Int
    var status: RenderableEthereumAccount.Status
    private var amount: CryptoAmount {
        .init(amount: BigUInt(visibleAmount.toCent()), token: token)
    }

    var id: String {
        accountId
    }

    var icon: AccountIcon {
        if let url = token.logo {
            return .url(url)
        } else {
            return .image(.imageOutlineIcon)
        }
    }

    var wrapped: Bool {
        false
    }

    var title: String {
        token.name
    }

    var subtitle: String {
        CryptoFormatterFactory.formatter(
            with: amount.token,
            style: .short
        )
            .string(amount: amount)
    }

    var detail: AccountDetail {
        switch status {
        case .ready:
            return .button(label: L10n.claim, enabled: true)
        case .isProcessing:
            return .button(label: L10n.claim, enabled: true)
        case .balanceToLow:
            return .text("")
        }
    }

    var extraAction: AccountExtraAction? {
        nil
    }

    var tags: AccountTags {
        var tags: AccountTags = []

        if status == .balanceToLow {
            if amount.amount == 0 {
                tags.insert(.hidden)
            } else {
                tags.insert(.ignore)
            }
        }
        return tags
    }

    var isLoading: Bool {
        switch status {
        case .isProcessing:
            return true
        default:
            return false
        }
    }
}

private extension Int {
    func toCent() -> Double {
        Double(self * 10_000)
    }
}

struct OutgoingBankTransferRenderableAccount: RenderableAccount {
    let accountId: String
    let fiat: Fiat
    let rawAmount: Int
    var status: RenderableEthereumAccount.Status
    private var amount: CurrencyAmount {
        CurrencyAmount(value: BigDecimal(floatLiteral: visibleAmount), currencyCode: fiat.code)
    }

    var visibleAmount: Double { Double(rawAmount) / 100 }

    var id: String { accountId }

    var icon: AccountIcon { .image(.iconUpload) }

    var wrapped: Bool { false }

    var title: String { L10n.outcomingTransfer }

    var subtitle: String {
        CurrencyFormatter(defaultValue: "", hideSymbol: true).string(amount: amount).appending(" \(fiat.code)")
    }

    var detail: AccountDetail {
        switch status {
        case .ready, .isProcessing:
            return .button(label: L10n.confirm, enabled: true)
        case .balanceToLow:
            return .text("")
        }
    }

    var extraAction: AccountExtraAction? { nil }

    var tags: AccountTags {
        var tags: AccountTags = []

        if status == .balanceToLow {
            if visibleAmount == 0 {
                tags.insert(.hidden)
            } else {
                tags.insert(.ignore)
            }
        }
        return tags
    }

    var isLoading: Bool {
        switch status {
        case .isProcessing:
            return true
        default:
            return false
        }
    }
}

class BankTransferRenderableAccountFactory {
    static func renderableAccount(accounts: UserAccounts, actions: [any UserAction]) -> [any RenderableAccount] {
        var transactions = [any RenderableAccount]()
        if
            let usdc = accounts.usdc,
            usdc.availableBalance > 0,
            let address = try? EthereumAddress(
                hex: EthereumAddresses.ERC20.usdc.rawValue,
                eip55: false
        ) {
            let token = EthereumToken(
                name: SolanaToken.usdc.name,
                symbol: SolanaToken.usdc.symbol,
                decimals: 6,
                logo: URL(string: SolanaToken.usdc.logoURI ?? ""),
                contractType: .erc20(contract: address)
            )
            let action = actions
                .compactMap { $0 as? BankTransferClaimUserAction }
                .first(where: { action in
                    action.id == usdc.accountID
                })
            transactions.append(
                BankTransferRenderableAccount(
                    accountId: usdc.accountID,
                    token: token,
                    visibleAmount: usdc.availableBalance,
                    rawAmount: usdc.totalBalance,
                    status: action?.status == .processing ? .isProcessing : .ready
                )
            )
        }

        if let eur = accounts.eur, let balance = eur.availableBalance, balance > 0 {
            transactions.append(
                OutgoingBankTransferRenderableAccount(
                    accountId: eur.accountID,
                    fiat: .eur,
                    rawAmount: balance,
                    status: .ready
                )
            )
        }
        return transactions
    }
}
