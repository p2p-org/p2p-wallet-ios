import Foundation
import SolanaSwift
import KeyAppBusiness

// As NFT Address
private let scamAddresses: Set<String> = [
    "XzR7CUMqhDBzbAm4aUNvwhVCxjWGn1KEvqTp3Y8fFCD"
]

extension Wallet {
    // Hide NFT TODO: $0.token.supply == 1 is also a condition for NFT but skipped atm
    var isNFTToken: Bool {
        (token.decimals == 0) || scamAddresses.contains(token.address)
    }
}

extension Wallet: Identifiable {
    public var id: String {
        return name + pubkey
    }
}
