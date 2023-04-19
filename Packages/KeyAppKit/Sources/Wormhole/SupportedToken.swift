import Foundation
import KeyAppKitCore

public enum SupportedToken {
    public static let usdt: SolanaToken = .init(
            _tags: nil,
            chainId: 101,
            address: "Dn4noZ5jgGfkntzcQSUZ8czkreiZ1ForXYoV2H8Dm7S1",
            symbol: "USDTet",
            name: "Tether USD (Portal from Ethereum)",
            decimals: 6,
            logoURI: "https://assets.coingecko.com/coins/images/325/large/Tether.png?1668148663",
            extensions: .init(coingeckoId: "tether")
        )

    public enum ERC20: String, CaseIterable {
        case sol = "0xd31a59c85ae9d8edefec411d448f90841571b89c"
        case usdc = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        case usdt = "0xdac17f958d2ee523a2206206994597c13d831ec7"
        case ust = "0xa693b19d2931d498c5b318df961919bb4aee87a5"
        case luna = "0xbd31ea8212119f94a611fa969881cba3ea06fa3d"
        case bnb = "0x418d75f65a02b3d53b2418fb8e1fe493759c7605"
        case matic = "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0"
        case avax = "0x85f138bfee4ef8e540890cfb48f620571d67eda3"

        public var solanaMintAddress: String {
            let map: [ERC20: String] = [
                .sol: "So11111111111111111111111111111111111111112",
                .usdc: "A9mUU4qviSctJVPJdBJWkb28deg915LYJKrzQ19ji3FM",
                .usdt: "Dn4noZ5jgGfkntzcQSUZ8czkreiZ1ForXYoV2H8Dm7S1",
                .ust: "9vMJfxuKxXBoEa7rM12mYLMwTacLMLDJqHozw96WQL8i",
                .luna: "F6v4wfAdJB8D8p77bMXZgYt8TDKsYxLYxH5AFhUkYx9W",
                .bnb: "9gP2kCy3wA1ctvYWQk75guqXuHfrEomqydHLtcTCqiLa",
                .matic: "C7NNPWuZCNjZBfW5p6JvGsR8pUdsRpEdP1ZAhnoDwj7h",
                .avax: "KgV1GvrHQmRBY8sHQQeUKwTm2r2h8t4C8qt12Cw1HVE",
            ]

            return map[self]!
        }
    }

    public struct WormholeBridge {
        public let name: String
        public let coingekoID: String
        public let ethAddress: String?
        public let solAddress: String?
        public let receiveFromAddress: String?
    }

    public static let bridges: [WormholeBridge] = [
        .init(
            name: "SOL",
            coingekoID: "solana",
            ethAddress: "0xD31a59c85aE9D8edEFeC411D448f90841571b89c",
            solAddress: "So11111111111111111111111111111111111111112",
            receiveFromAddress: nil
        ),
        .init(
            name: "ETH",
            coingekoID: "ethereum",
            ethAddress: nil,
            solAddress: "7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs",
            receiveFromAddress: "2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk"
        ),
        .init(
            name: "USDC",
            coingekoID: "usd-coin",
            ethAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            solAddress: "A9mUU4qviSctJVPJdBJWkb28deg915LYJKrzQ19ji3FM",
            receiveFromAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        ),
        .init(
            name: "USDT",
            coingekoID: "tether",
            ethAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
            solAddress: "Dn4noZ5jgGfkntzcQSUZ8czkreiZ1ForXYoV2H8Dm7S1",
            receiveFromAddress: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"
        ),
        .init(
            name: "UST",
            coingekoID: "terrausd",
            ethAddress: "0xa693b19d2931d498c5b318df961919bb4aee87a5",
            solAddress: "9vMJfxuKxXBoEa7rM12mYLMwTacLMLDJqHozw96WQL8i",
            receiveFromAddress: nil
        ),
        .init(
            name: "CRV",
            coingekoID: "curve-dao-token",
            ethAddress: "0xd533a949740bb3306d119cc777fa900ba034cd52",
            solAddress: "7gjNiPun3AzEazTZoFEjZgcBMeuaXdpjHq2raZTmTrfs",
            receiveFromAddress: nil
        ),
        .init(
            name: "LUNA",
            coingekoID: "terra-luna",
            ethAddress: "0xbd31ea8212119f94a611fa969881cba3ea06fa3d",
            solAddress: "F6v4wfAdJB8D8p77bMXZgYt8TDKsYxLYxH5AFhUkYx9W",
            receiveFromAddress: nil
        ),
        .init(
            name: "BNB",
            coingekoID: "binancecoin",
            ethAddress: "0x418d75f65a02b3d53b2418fb8e1fe493759c7605",
            solAddress: "9gP2kCy3wA1ctvYWQk75guqXuHfrEomqydHLtcTCqiLa",
            receiveFromAddress: nil
        ),
        .init(
            name: "Matic",
            coingekoID: "matic-network",
            ethAddress: "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0",
            solAddress: "C7NNPWuZCNjZBfW5p6JvGsR8pUdsRpEdP1ZAhnoDwj7h",
            receiveFromAddress: nil
        ),
        .init(
            name: "AVAX",
            coingekoID: "avalanche-2",
            ethAddress: "0x85f138bfee4ef8e540890cfb48f620571d67eda3",
            solAddress: "KgV1GvrHQmRBY8sHQQeUKwTm2r2h8t4C8qt12Cw1HVE",
            receiveFromAddress: nil
        ),
    ]
}
