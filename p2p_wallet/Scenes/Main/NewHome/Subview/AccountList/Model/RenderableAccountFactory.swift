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
        // If contract type is ERC-20 and has a SOL address -> make a SOL instance
        if case let .erc20(contract) = with.token.contractType, Wormhole.SupportedToken.ERC20(rawValue: contract.hex(eip55: false)) == .sol {
            return SOLRenderableEthereumAccount(
                account: with,
                isClaiming: isClaiming,
                onTap: onTap,
                onClaim: onClain
            )
        } else {
            return RenderableEthereumAccount(
                account: with,
                isClaiming: isClaiming,
                onTap: onTap,
                onClaim: onClain
            )
        }
    }
}
