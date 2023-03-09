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

        var solanaMintAddress: String {
            let map: [ERC20: String] = [
                .sol: "So11111111111111111111111111111111111111112",
                .usdc: "A9mUU4qviSctJVPJdBJWkb28deg915LYJKrzQ19ji3FM",
                .usdt: "Dn4noZ5jgGfkntzcQSUZ8czkreiZ1ForXYoV2H8Dm7S1",
                .ust: "7gjNiPun3AzEazTZoFEjZgcBMeuaXdpjHq2raZTmTrfs",
                .luna: "F6v4wfAdJB8D8p77bMXZgYt8TDKsYxLYxH5AFhUkYx9W",
                .bnb: "9gP2kCy3wA1ctvYWQk75guqXuHfrEomqydHLtcTCqiLa",
                .matic: "C7NNPWuZCNjZBfW5p6JvGsR8pUdsRpEdP1ZAhnoDwj7h",
                .avax: "KgV1GvrHQmRBY8sHQQeUKwTm2r2h8t4C8qt12Cw1HVE",
            ]

            return map[self]!
        }
    }
}
