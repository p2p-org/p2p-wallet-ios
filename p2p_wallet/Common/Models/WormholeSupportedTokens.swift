import Foundation
import Wormhole
import SolanaSwift

class WormholeSupportedTokens {
    static var bridges: [SupportedToken.WormholeBridge] {
        SupportedToken.bridges.filter { bridge in
            return bridge.solAddress == TokenMetadata.nativeSolana.mintAddress ? available(.solanaEthAddressEnabled) : true
        }
    }
}
