import Foundation

public enum TokenPrimaryKey: Hashable, Codable {
    case native
    case contract(String)

    /// Token identify
    public var id: String {
        switch self {
        case .native:
            return "native"
        case let .contract(value):
            return value
        }
    }
}

/// Any token for easy converable
public protocol AnyToken {
    /// It's a normalised string of token primary key.
    ///
    /// Format: {network}-{tokenPrimaryKey.id}
    /// It can be smart contract address or `native` text in case native
    /// token.
    var id: String { get }

    /// Normalised token id.
    var primaryKey: TokenPrimaryKey { get }

    /// The network, that define this token.
    var network: TokenNetwork { get }

    /// Token symbol
    var symbol: String { get }

    /// Token full name
    var name: String { get }

    /// Decimal for token
    var decimals: UInt8 { get }

    /// Token address
    ///
    /// Use this property with attention. For example native token doesn't have mint address, the address of wrapped sol
    /// will be used.
    @available(*, deprecated, message: "Legacy code")
    var address: String { get }

//    var keyAppExtension: KeyAppTokenExtension { get }
}

public extension AnyToken {
    var id: String { "\(network)-\(primaryKey.id)" }

    var asSomeToken: SomeToken {
        SomeToken(
            tokenPrimaryKey: primaryKey,
            symbol: symbol,
            name: name,
            decimals: decimals,
            network: network
//            keyAppExtension: keyAppExtension
        )
    }

    var address: String {
        switch network {
        case .solana:
            switch primaryKey {
            case .native:
                return SolanaToken.nativeSolana.mintAddress
            case let .contract(address):
                return address
            }
        default:
            return primaryKey.id
        }
    }
}

public enum TokenNetwork: String, Hashable, Codable {
    case solana
    case ethereum
}

/// Base application token
public struct SomeToken: AnyToken, Hashable, Codable {
    public let primaryKey: TokenPrimaryKey

    public let symbol: String

    public let name: String

    public let decimals: UInt8

    public let network: TokenNetwork

//    public var keyAppExtension: KeyAppTokenExtension

    public init(
        tokenPrimaryKey: TokenPrimaryKey,
        symbol: String,
        name: String,
        decimals: UInt8,
        network: TokenNetwork
//        keyAppExtension: KeyAppTokenExtension
    ) {
        primaryKey = tokenPrimaryKey
        self.symbol = symbol
        self.name = name
        self.decimals = decimals
        self.network = network
//        self.keyAppExtension = keyAppExtension
    }
}
