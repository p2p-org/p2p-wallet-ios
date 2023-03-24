//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import KeyAppKitCore
import Web3

/// Ethereum token structure
public struct EthereumToken: Hashable {
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

    /// Erc-20 Token
    internal init(address: EthereumAddress, metadata: EthereumTokenMetadata) {
        self.name = metadata.name ?? ""
        self.symbol = metadata.symbol ?? ""
        self.decimals = metadata.decimals ?? 1
        self.logo = metadata.logo
        self.contractType = .erc20(contract: address)
    }

    /// Native token
    public init() {
        self.name = "Ethereum"
        self.symbol = "ETH"
        self.decimals = 18
        self.logo = URL(string: "https://assets.coingecko.com/coins/images/279/large/ethereum.png?1595348880")
        self.contractType = .native
    }
}

public extension EthereumToken {
    /// Ethereum token contract standards.
    enum ContractType: Hashable {
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
