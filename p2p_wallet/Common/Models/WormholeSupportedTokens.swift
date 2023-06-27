import Foundation
import Wormhole
import SolanaSwift

class WormholeSupportedTokens {
    static var bridges: [SupportedToken.WormholeBridge] {
        SupportedToken.bridges.filter { bridge in
            return bridge.solAddress == Token.nativeSolana.address ? available(.solanaEthAddressEnabled) : true
        }
    }
}
