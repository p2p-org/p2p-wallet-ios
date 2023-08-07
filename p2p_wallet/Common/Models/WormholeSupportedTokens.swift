import Foundation
import SolanaSwift
import Wormhole

class WormholeSupportedTokens {
    static var bridges: [SupportedToken.WormholeBridge] {
        SupportedToken.bridges.filter { bridge in
            bridge.solAddress == TokenMetadata.nativeSolana.mintAddress ? available(.solanaEthAddressEnabled) : true
        }
    }
}
