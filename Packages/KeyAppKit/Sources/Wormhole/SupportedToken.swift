//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation

public enum SupportedToken {
    public enum ERC20: String, CaseIterable {
        case sol = "0xD31a59c85aE9D8edEFeC411D448f90841571b89c"
        case usdc = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        case usdt = "0xdac17f958d2ee523a2206206994597c13d831ec7"
        case ust = "0xa693b19d2931d498c5b318df961919bb4aee87a5"
        case crv = "0xd533a949740bb3306d119cc777fa900ba034cd52"
        case luna = "0xbd31ea8212119f94a611fa969881cba3ea06fa3d"
        case bnb = "0x418d75f65a02b3d53b2418fb8e1fe493759c7605"
        case matic = "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0"
        case avax = "0x85f138bfee4ef8e540890cfb48f620571d67eda3"
    }
}
