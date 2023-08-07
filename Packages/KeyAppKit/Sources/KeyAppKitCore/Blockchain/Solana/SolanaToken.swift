import Foundation
import SolanaSwift

public typealias SolanaToken = TokenMetadata

public extension SolanaToken {
    var wrapped: Bool {
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

    var isLiquidity: Bool {
        tags.contains(where: { $0.name == "lp-token" })
    }
}

extension SolanaToken: AnyToken {
    public var primaryKey: TokenPrimaryKey {
        if isNative {
            return .native
        } else {
            return .contract(mintAddress)
        }
    }

    public var network: TokenNetwork {
        .solana
    }

    public var keyAppExtension: KeyAppTokenExtension {
        KeyAppTokenExtension(data: extensions ?? [:])
    }
}
