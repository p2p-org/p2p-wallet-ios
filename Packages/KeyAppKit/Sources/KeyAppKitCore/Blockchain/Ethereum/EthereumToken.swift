import Foundation
import Web3

/// Ethereum token structure
public struct EthereumToken: Hashable, Codable, Equatable {
    /// Token name
    public let name: String

    /// Token symbol
    public let symbol: String

    /// Token decimals
    public let decimals: UInt8

    /// Token logo
    public let logo: URL?

    /// Token contract type
    public var contractType: ContractType

    /// Native token
    public init() {
        name = "Ethereum"
        symbol = "ETH"
        decimals = 18
        logo = URL(string: "https://assets.coingecko.com/coins/images/279/large/ethereum.png?1595348880")
        contractType = .native
    }

    public init(name: String, symbol: String, decimals: UInt8, logo: URL?, contractType: ContractType) {
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.logo = logo
        self.contractType = contractType
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.contractType == rhs.contractType
    }
}

public extension EthereumToken {
    /// Ethereum token contract standards.
    enum ContractType: Hashable, Codable, Equatable {
        /// Native token
        case native

        /// ERC-20 Token standard
        case erc20(contract: EthereumAddress)
    }
}

extension EthereumToken: AnyToken {
    public var tokenPrimaryKey: String {
        switch contractType {
        case .native:
            return "native-ethereum"
        case let .erc20(contract):
            return "erc-20-\(contract.hex(eip55: false))"
        }
    }
}
