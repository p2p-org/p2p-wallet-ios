//
//  Token+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation
import SolanaSwift

extension Token {
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
        var imageName = symbol
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "Ü", with: "U")

        // parse liquidity tokens
        let liquidityTokensPrefixes = ["Raydium", "Orca", "Mercurial"]
        for prefix in liquidityTokensPrefixes {
            if name.contains("\(prefix) "), imageName.contains("-") {
                imageName = "\(prefix)-" + imageName
            }
        }
        return UIImage(named: imageName)
        // swiftlint:enable swiftgen_assets
    }
    
    var maxAmount: Double {
        (Double(Lamports.max) / pow(10, Double(decimals)))
            .rounded(decimals: 0, roundingMode: .down)

    }
}

extension Token {
    // MARK: - Common tokens
    
    static var slnd: Token {
        .init(
            _tags: ["solend", "lending"],
            chainId: 101,
            address: "SLNDpmoWTVADgEdndyvWzroNL7zSi1dF9PC3xHGtPwp",
            symbol: "SLND",
            name: "Solend",
            decimals: 6,
            logoURI: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/SLNDpmoWTVADgEdndyvWzroNL7zSi1dF9PC3xHGtPwp/logo.png",
            extensions: .init(
                website: "https://solend.fi",
                twitter: "https://twitter.com/solendprotocol",
                serumV3Usdc: "F9y9NM83kBMzBmMvNT18mkcFuNAPhNRhx7pnz9EDWwfv",
                coingeckoId: "solend"
            )
        )
    }
    
    static var mSOL: Token {
        .init(
            _tags: nil,
            chainId: 101,
            address: "mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So",
            symbol: "mSOL",
            name: "Marinade staked SOL (mSOL)",
            decimals: 9,
            logoURI: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So/logo.png",
            extensions: .init(
                website: "https://marinade.finance",
                twitter: "https://twitter.com/MarinadeFinance",
                github: "https://github.com/marinade-finance",
                medium: "https://medium.com/marinade-finance",
                discord: "https://discord.gg/mGqZA5pjRN",
                serumV3Usdt: "HxkQdUnrPdHwXP5T9kewEXs3ApgvbufuTfdw9v1nApFd",
                serumV3Usdc: "6oGsL2puUgySccKzn9XA9afqF217LfxP5ocq4B3LWsjy",
                coingeckoId: "msol"
            )
        )
    }
    
    static var stSOL: Token {
        .init(
            _tags: nil,
            chainId: 101,
            address: "7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj",
            symbol: "stSOL",
            name: "Lido Staked SOL",
            decimals: 9,
            logoURI: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj/logo.png",
            extensions: .init(
                website: "https://solana.lido.fi/",
                twitter: "https://twitter.com/LidoFinance",
                github: "https://github.com/ChorusOne/solido",
                discord: "https://discord.gg/w9pXXgQPu8",
                serumV3Usdc: "5F7LGsP1LPtaRV7vVKgxwNYX4Vf22xvuzyXjyar7jJqp",
                coingeckoId: "lido-staked-sol"
            )
        )
    }
    
    static var raydium: Token {
        .init(
            _tags: nil,
            chainId: 101,
            address: "4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R",
            symbol: "RAY",
            name: "Raydium",
            decimals: 6,
            logoURI: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R/logo.png",
            extensions: .init(
                website: "https://raydium.io/",
                serumV3Usdt: "teE55QrL4a4QSfydR9dnHF97jgCfptpuigbb53Lo95g",
                serumV3Usdc: "2xiv8A5xrJ7RnGdxXB42uFEkYHJjszEhaJyKKt4WaLep",
                coingeckoId: "raydium"
            )
        )
    }
    
    static var srm: Token {
        .init(
            _tags: nil,
            chainId: 101,
            address: "SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt",
            symbol: "SRM",
            name: "Serum",
            decimals: 6,
            logoURI: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt/logo.png",
            extensions: .init(
                website: "https://projectserum.com/",
                serumV3Usdt: "AtNnsY1AyRERWJ8xCskfz38YdvruWVJQUVXgScC1iPb",
                serumV3Usdc: "ByRys5tuUWDgL73G8JBAEfkdFf8JWBzPBDHsBVQ5vbQA",
                coingeckoId: "serum"
            )
        )
    }
    
    static var orca: Token {
        .init(
            _tags: nil,
            chainId: 101,
            address: "orcaEKTdK7LKz57vaAYr9QeNsVEPfiu6QeMU1kektZE",
            symbol: "ORCA",
            name: "Orca",
            decimals: 6,
            logoURI: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/orcaEKTdK7LKz57vaAYr9QeNsVEPfiu6QeMU1kektZE/logo.png",
            extensions: .init(
                website: "https://orca.so",
                serumV3Usdc: "8N1KkhaCYDpj3awD58d85n973EwkpeYnRp84y1kdZpMX",
                coingeckoId: "orca"
            )
        )
    }
    
    // MARK: - Common grouped tokens

    static var solendSupportedTokens: [Token] = [
        .nativeSolana,
        .usdc,
        .usdt,
        .eth,
        .slnd,
        .mSOL,
        .stSOL,
        .raydium,
        .srm,
        .orca
    ]
    
    static var moonpaySellSupportedTokens: [Token] = [
        .nativeSolana
    ]
}
