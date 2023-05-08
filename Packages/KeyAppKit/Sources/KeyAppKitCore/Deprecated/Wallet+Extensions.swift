import Foundation
import SolanaPricesAPIs

public struct SolanaWalletUserInfo: Hashable {
    public var price: CurrentPrice?
}

/// Legacy code. Wallet struct doesn't have price field. We added it by using ``userInfo``.
public extension Wallet {
    @available(*, deprecated)
    var _price: CurrentPrice? {
        get {
            getParsedUserInfo().price
        }
        set {
            var userInfo = getParsedUserInfo()
            userInfo.price = newValue
            self.userInfo = userInfo
        }
    }

    @available(*, deprecated)
    var _priceInCurrentFiat: Double? {
        _price?.value
    }

    @available(*, deprecated)
    var _amountInCurrentFiat: Double {
        (amount ?? 0.0) * (_priceInCurrentFiat ?? 0.0)
    }

    @available(*, deprecated)
    private func getParsedUserInfo() -> SolanaWalletUserInfo {
        userInfo as? SolanaWalletUserInfo ?? SolanaWalletUserInfo()
    }
}
