import Foundation
import Wormhole
import KeyAppBusiness
import KeyAppKitCore

final class RenderableAccountFactory {
    private init() {}

    static func account(
        with: EthereumAccount,
        isClaiming: Bool,
        onTap: (() -> Void)? = nil,
        onClain: (() -> Void)?
    ) -> any ClaimableRenderableAccount {
        return RenderableEthereumAccount(
            account: with,
            isClaiming: isClaiming,
            onTap: onTap,
            onClaim: onClain
        )
    }
}
