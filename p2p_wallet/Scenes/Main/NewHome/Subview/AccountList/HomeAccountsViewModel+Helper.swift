import Foundation
import SolanaSwift
import KeyAppBusiness
import KeyAppKitCore

extension Wallet {
    // Hide NFT TODO: $0.token.supply == 1 is also a condition for NFT but skipped atm
    var isNFTToken: Bool {
        token.decimals == 0
    }
}

extension Wallet: Identifiable {
    public var id: String {
        return name + pubkey
    }
}
