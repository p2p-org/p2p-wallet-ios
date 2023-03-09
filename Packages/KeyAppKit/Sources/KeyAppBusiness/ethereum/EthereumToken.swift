//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import Web3

/// Ethereum token structure
public struct EthereumToken: Equatable {
    /// Token name
    public let name: String
    
    /// Token symbol
    public let symbol: String
    
    /// Token decimals
    public let decimals: UInt8
    
    /// Token logo
    public let logo: URL?
    
    /// Token contract type
    public let contractType: ContractType

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
        self.decimals = 1
        self.logo = URL(string: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB/logo.png")
        self.contractType = .native
    }
}

public extension EthereumToken {
    /// Ethereum token contract standards.
    enum ContractType: Equatable {
        /// Native token
        case native
        
        /// ERC-20 Token standard
        case erc20(contract: EthereumAddress)
    }
}
