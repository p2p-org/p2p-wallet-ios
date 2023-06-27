import Foundation
import SolanaSwift

public typealias SolanaToken = TokenMetadata

extension SolanaToken {
    public var wrapped: Bool {
        if tags.contains(where: { $0.name == "wrapped-sollet" }) {
            return true
        }

        if tags.contains(where: { $0.name == "wrapped" }),
           tags.contains(where: { $0.name == "wormhole" })
        {
            return true
        }

        return false
    }

    public var isLiquidity: Bool {
        tags.contains(where: { $0.name == "lp-token" })
    }
}

extension SolanaToken: AnyToken {
    public var tokenPrimaryKey: String {
        isNative ? "native" : address
    }

    public var network: TokenNetwork {
        .solana
    }
}
