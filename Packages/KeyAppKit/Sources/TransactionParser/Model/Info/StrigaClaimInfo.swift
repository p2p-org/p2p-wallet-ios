import Foundation
import SolanaSwift

/// A struct that contains all information about striga claimming.
public struct StrigaClaimInfo: Hashable {
    public let amount: Double?
    public let token: Token?
    public let recevingPubkey: String?
    
    public init(amount: Double?, token: Token?, recevingPubkey: String?) {
        self.amount = amount
        self.token = token
        self.recevingPubkey = recevingPubkey
    }
}

extension StrigaClaimInfo: Info {
    public var symbol: String? {
        token?.symbol
    }
    
    public var mintAddress: String? {
        token?.address
    }
}
