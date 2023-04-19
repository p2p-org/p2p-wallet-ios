import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift
import Wormhole

struct RenderableEthereumAccount: RenderableAccount {
    let account: EthereumAccount

    let status: Status

    var id: String {
        switch account.token.contractType {
        case .native:
            return account.address
        case let .erc20(contract):
            return contract.hex(eip55: false)
        }
    }

    var icon: AccountIcon {
        if let url = (account.wormholeNativeCounterpart() ?? account).token.logo {
            return .url(url)
        } else {
            return .image(.imageOutlineIcon)
        }
    }

    var wrapped: Bool {
        false
    }

    var title: String {
        (account.wormholeNativeCounterpart() ?? account).token.name
    }

    var subtitle: String {
        CryptoFormatterFactory.formatter(with: (account.wormholeNativeCounterpart() ?? account).representedBalance.token, style: .short)
            .string(for: account.representedBalance)
            ?? "0 \((account.wormholeNativeCounterpart() ?? account).token.symbol)"
    }

    var detail: AccountDetail {
        switch status {
        case .readyToClaim:
            return .button(label: L10n.claim, enabled: true)
        case .isClamming:
            return .button(label: L10n.claiming, enabled: false)
        case .balanceToLow:
            if let balanceInFiat = account.balanceInFiat {
                return .text(CurrencyFormatter().string(amount: balanceInFiat))
            } else {
                return .text("")
            }
        }
    }

    var extraAction: AccountExtraAction? {
        nil
    }

    var tags: AccountTags {
        var tags: AccountTags = []

        if status == .balanceToLow {
            tags.insert(.ignore)
        }

        return tags
    }
}

extension RenderableEthereumAccount {
    enum Status: Equatable {
        case readyToClaim
        case isClamming
        case balanceToLow
    }
}

extension EthereumAccount {
    func wormholeNativeCounterpart() -> EthereumAccount? {
        if case let .erc20(contract) = self.token.contractType {
            if Wormhole.SupportedToken.ERC20(rawValue: contract.hex(eip55: false)) == .sol {
                return EthereumAccount(
                    address: self.address,
                    token: .init(
                        name: Token.nativeSolana.name,
                        symbol: Token.nativeSolana.symbol,
                        decimals: self.token.decimals,
                        logo: URL(string: Token.nativeSolana.logoURI ?? ""),
                        contractType: self.token.contractType
                    ),
                    balance: self.balance,
                    price: self.price
                )
            } else if Wormhole.SupportedToken.ERC20(rawValue: contract.hex(eip55: false)) == .bnb {
                return EthereumAccount(
                    address: self.address,
                    token: .init(
                        name: "BNB",
                        symbol: "BNB",
                        decimals: self.token.decimals,
                        logo: URL(string: "https://assets.coingecko.com/coins/images/825/large/bnb-icon2_2x.png?1644979850")!,
                        contractType: self.token.contractType
                    ),
                    balance: self.balance,
                    price: self.price
                )
            }
        }
        return nil
    }
}
