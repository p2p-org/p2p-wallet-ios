//
//  File.swift
//
//
//  Created by Giang Long Tran on 25.04.2023.
//

import Foundation
import KeyAppKitCore

/// Fix token meta information.
class EthereumTokenDataCorrection {
    func correct(token: EthereumToken) -> EthereumToken {
        if case let .erc20(contract) = token.contractType {
            switch contract.hex(eip55: false) {
            case EthereumAddresses.ERC20.sol.rawValue:
                return fixSOL(token: token)
            case EthereumAddresses.ERC20.bnb.rawValue:
                return fixBNB(token: token)
            case EthereumAddresses.ERC20.usdc.rawValue:
                return fixUSDC(token: token)
            case EthereumAddresses.ERC20.usdt.rawValue:
                return fixUSDT(token: token)
            default:
                return token
            }
        }

        return token
    }

    private func fixUSDT(token: EthereumToken) -> EthereumToken {
        EthereumToken(
            name: SolanaToken.usdt.name,
            symbol: SolanaToken.usdt.symbol,
            decimals: token.decimals,
            logo: URL(string: SolanaToken.usdt.logoURI ?? ""),
            contractType: token.contractType
        )
    }

    private func fixUSDC(token: EthereumToken) -> EthereumToken {
        EthereumToken(
            name: SolanaToken.usdc.name,
            symbol: SolanaToken.usdc.symbol,
            decimals: token.decimals,
            logo: URL(string: SolanaToken.usdc.logoURI ?? ""),
            contractType: token.contractType
        )
    }

    private func fixSOL(token: EthereumToken) -> EthereumToken {
        EthereumToken(
            name: SolanaToken.nativeSolana.name,
            symbol: SolanaToken.nativeSolana.symbol,
            decimals: token.decimals,
            logo: URL(string: SolanaToken.nativeSolana.logoURI ?? ""),
            contractType: token.contractType
        )
    }

    private func fixBNB(token: EthereumToken) -> EthereumToken {
        EthereumToken(
            name: "BNB",
            symbol: "BNB",
            decimals: token.decimals,
            logo: URL(string: "https://assets.coingecko.com/coins/images/825/large/bnb-icon2_2x.png?1644979850")!,
            contractType: token.contractType
        )
    }
}
