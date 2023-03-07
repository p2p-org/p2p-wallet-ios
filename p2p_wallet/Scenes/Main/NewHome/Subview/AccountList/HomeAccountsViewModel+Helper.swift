//
//  HomeAccountsViewModel+Helper.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.03.2023.
//

import Foundation
import SolanaSwift
import KeyAppBusiness

extension Wallet {
    var isNFTToken: Bool {
        // Hide NFT TODO: $0.token.supply == 1 is also a condition for NFT but skipped atm
        token.decimals == 0
    }
}

extension Wallet: Identifiable {
    public var id: String {
        return name + pubkey
    }
}

extension HomeAccountsViewModel {
    static func shouldInIgnoreSection(rendableAccount: RendableSolanaAccount, hideZeroBalance: Bool) -> Bool {
        if rendableAccount.isInIgnoreList {
            return true
        } else if hideZeroBalance, rendableAccount.account.data.lamports == 0 {
            return true
        } else {
            return false
        }
    }

    static func shouldInVisiableSection(rendableAccount: RendableSolanaAccount, hideZeroBalance: Bool) -> Bool {
        if rendableAccount.tags.contains(.favourite) {
            return true
        } else if hideZeroBalance, rendableAccount.account.data.lamports == 0 {
            return false
        } else {
            return true
        }
    }

    static var defaultSolanaAccountsSorter: (SolanaAccountsService.Account, SolanaAccountsService.Account) -> Bool {
        { lhs, rhs in
            // prefers non-liquidity token than liquidity tokens
            if lhs.data.token.isLiquidity != rhs.data.token.isLiquidity {
                return !lhs.data.token.isLiquidity
            }

            // prefers prioritized tokens than others
            let prioritizedTokenMints = [
                PublicKey.usdcMint.base58EncodedString,
                PublicKey.usdtMint.base58EncodedString
            ]
            for mint in prioritizedTokenMints {
                if mint == lhs.data.token.address || mint == rhs.data.token.address {
                    return mint == lhs.data.token.address
                }
            }

            // prefers token which more value than the other in fiat
            if lhs.amountInFiat != rhs.amountInFiat {
                return lhs.amountInFiat > rhs.amountInFiat
            }

            // prefers known token than unknown ones
            if lhs.data.token.symbol.isEmpty != rhs.data.token.symbol.isEmpty {
                return !lhs.data.token.symbol.isEmpty
            }

            // prefers token which more balance than the others
            if lhs.data.amount != rhs.data.amount {
                return lhs.data.amount.orZero > rhs.data.amount.orZero
            }

            // sort by symbol
            if lhs.data.token.symbol != rhs.data.token.symbol {
                return lhs.data.token.symbol < rhs.data.token.symbol
            }

            // then name
            return lhs.data.name < rhs.data.name
        }
    }
}
