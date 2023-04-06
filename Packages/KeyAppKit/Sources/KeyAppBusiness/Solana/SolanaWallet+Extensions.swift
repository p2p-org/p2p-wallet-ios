import Foundation
import SolanaPricesAPIs
import SolanaSwift

public struct SolanaWalletUserInfo: Hashable {
    public var price: CurrentPrice?
}

/// Legacy code. Wallet struct doesn't have price field. We added it by using ``userInfo``.
public extension Wallet {
    @available(*, deprecated)
    var price: CurrentPrice? {
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
    var priceInCurrentFiat: Double? {
        price?.value
    }

    @available(*, deprecated)
    var amountInCurrentFiat: Double {
        (amount ?? 0.0) * (priceInCurrentFiat ?? 0.0)
    }

    @available(*, deprecated)
    func getParsedUserInfo() -> SolanaWalletUserInfo {
        userInfo as? SolanaWalletUserInfo ?? SolanaWalletUserInfo()
    }
}
