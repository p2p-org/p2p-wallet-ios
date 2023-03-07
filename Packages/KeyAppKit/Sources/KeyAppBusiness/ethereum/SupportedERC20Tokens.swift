//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import Web3

enum WormholeSupportedERC20Tokens {
    static let all: [EthereumERC20Token] = [
        Self.usdc,
        Self.usdt,
        Self.eth,
        Self.dai,
        Self.wbtc,
        Self.usdk,
        Self.frax,
        Self.shib,
        Self.sushi,
        Self.dydx,
        Self.mana,
        Self.sand,
        Self.uni,
        Self.ldo,
        Self.hxro,
        
    ]
    
    static let usdc = EthereumERC20Token(
        _address: try! .init(hex: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", eip55: true),
        name: "USD Coin",
        symbol: "USDC",
        decimals: 6
    )
    
    static let usdt = EthereumERC20Token(
        _address: try! .init(hex: "0xdAC17F958D2ee523a2206206994597C13D831ec7", eip55: true),
        name: "Tether USD",
        symbol: "USDT",
        decimals: 6
    )
    
    static let eth = EthereumERC20Token(
        _address: try! .init(hex: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", eip55: true),
        name: "Wrapped Ether",
        symbol: "WETH",
        decimals: 18
    )
    
    static let dai = EthereumERC20Token(
        _address: try! .init(hex: "0x6B175474E89094C44Da98b954EedeAC495271d0F", eip55: true),
        name: "Dai Stablecoin",
        symbol: "DAI",
        decimals: 18
    )
    
    static let wbtc = EthereumERC20Token(
        _address: try! .init(hex: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", eip55: true),
        name: "WBTC",
        symbol: "DAI",
        decimals: 8
    )
    
    static let usdk = EthereumERC20Token(
        _address: try! .init(hex: "0x1c48f86ae57291F7686349F12601910BD8D470bb", eip55: true),
        name: "USDK",
        symbol: "USDK",
        decimals: 18
    )
    
    static let frax = EthereumERC20Token(
        _address: try! .init(hex: "0x853d955aCEf822Db058eb8505911ED77F175b99e", eip55: true),
        name: "Frax",
        symbol: "FRAX",
        decimals: 18
    )
    
    static let shib = EthereumERC20Token(
        _address: try! .init(hex: "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE", eip55: true),
        name: "SHIBA INU",
        symbol: "SHIB",
        decimals: 18
    )
    
    static let sushi = EthereumERC20Token(
        _address: try! .init(hex: "0x6B3595068778DD592e39A122f4f5a5cF09C90fE2", eip55: true),
        name: "SushiToken",
        symbol: "SUSHI",
        decimals: 18
    )
    
    static let dydx = EthereumERC20Token(
        _address: try! .init(hex: "0x92D6C1e31e14520e676a687F0a93788B716BEff5", eip55: true),
        name: "dYdX",
        symbol: "DYDX",
        decimals: 18
    )
    
    static let mana = EthereumERC20Token(
        _address: try! .init(hex: "0x0F5D2fB29fb7d3CFeE444a200298f468908cC942", eip55: true),
        name: "Decentraland MANA",
        symbol: "MANA",
        decimals: 18
    )
    
    static let sand = EthereumERC20Token(
        _address: try! .init(hex: "0x3845badAde8e6dFF049820680d1F14bD3903a5d0", eip55: true),
        name: "SAND",
        symbol: "SAND",
        decimals: 18
    )
    
    static let uni = EthereumERC20Token(
        _address: try! .init(hex: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", eip55: true),
        name: "UNI",
        symbol: "Uniswap",
        decimals: 18
    )
    
    static let ldo = EthereumERC20Token(
        _address: try! .init(hex: "0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32", eip55: true),
        name: "Lido DAO Token",
        symbol: "LDO",
        decimals: 18
    )
    
    static let hxro = EthereumERC20Token(
        _address: try! .init(hex: "0x4bD70556ae3F8a6eC6C4080A0C327B24325438f3", eip55: true),
        name: "Hxro",
        symbol: "HXRO",
        decimals: 18
    )
}
