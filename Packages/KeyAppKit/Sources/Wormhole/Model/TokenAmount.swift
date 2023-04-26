//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import BigDecimal
import Foundation
import KeyAppKitCore
import Web3

public struct TokenAmount: Codable, Hashable {
    public let amount: String
    public let usdAmount: String

    private let chain: String
    private let contract: String?

    public var token: WormholeToken
    public var symbol: String
    public var name: String
    public var decimals: UInt8

    enum CodingKeys: String, CodingKey {
        case amount
        case usdAmount = "usd_amount"
        case chain
        case contract = "token"
        case symbol
        case name
        case decimals
    }

    init(
        amount: String,
        usdAmount: String,
        chain: String,
        contract: String?,
        symbol: String,
        name: String,
        decimals: UInt8
    ) throws {
        self.amount = amount
        self.usdAmount = usdAmount
        self.chain = chain
        self.contract = contract
        self.symbol = symbol
        self.name = name
        self.decimals = decimals

        token = try WormholeToken(chain: chain, token: contract)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        amount = try container.decode(String.self, forKey: .amount)
        usdAmount = try container.decode(String.self, forKey: .usdAmount)
        chain = try container.decode(String.self, forKey: .chain)
        contract = try container.decodeIfPresent(String.self, forKey: .contract)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        decimals = try container.decode(UInt8.self, forKey: .decimals)

        token = try WormholeToken(chain: chain, token: contract)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(usdAmount, forKey: .usdAmount)
        try container.encode(chain, forKey: .chain)
        try container.encode(contract, forKey: .contract)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(decimals, forKey: .decimals)
    }
}

extension TokenAmount: CryptoAmountConvertible {
    public var asCryptoAmount: CryptoAmount {
        switch token {
        case let .ethereum(contract):
            let contractType: EthereumToken.ContractType
            if let contract {
                contractType = .erc20(contract: try! EthereumAddress(hex: contract, eip55: false))
            } else {
                contractType = .native
            }

            return .init(
                bigUIntString: amount,
                token: EthereumToken(
                    name: name,
                    symbol: symbol,
                    decimals: decimals,
                    logo: nil,
                    contractType: contractType
                )
            )
        case let .solana(mint):
            let token: SolanaToken

            if let mint {
                token = SolanaToken(
                    _tags: nil,
                    chainId: 0,
                    address: mint,
                    symbol: symbol,
                    name: name,
                    decimals: decimals,
                    logoURI: nil,
                    extensions: nil
                )
            } else {
                token = .nativeSolana
            }

            return .init(
                bigUIntString: amount,
                token: token
            )
        }
    }
}

extension TokenAmount: CurrencyConvertible {
    public var asCurrencyAmount: CurrencyAmount {
        .init(usdStr: usdAmount)
    }
}
