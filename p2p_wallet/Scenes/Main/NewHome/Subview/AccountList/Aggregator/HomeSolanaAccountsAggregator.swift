//
//  HomeAccountsSolanaAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.04.2023.
//

import Foundation
import KeyAppKitCore
import SolanaSwift

/// Aggregating ``SolanaAccount`` into ``RendableAccount``.
struct HomeSolanaAccountsAggregator: DataAggregator {
    /// Transformation
    /// - Parameter input: Solana accounts, addresses of favourite and ignores, should be zero balance account hidden.
    /// - Returns: Renderable accounts.
    func transform(
        input: (
            accounts: [SolanaAccount],
            favourites: [String],
            ignores: [String],
            hideZeroBalance: Bool
        )
    ) -> [RenderableSolanaAccount] {
        let (accounts, favourites, ignores, hideZeroBalance) = input

        return accounts
            .filter { !$0.isNFTToken }
            .sorted(by: Self.defaultSorter)
            .map { account in
                var tags: AccountTags = []

                if favourites.contains(account.pubkey ?? "") {
                    tags.insert(.favourite)
                } else if ignores.contains(account.pubkey ?? "") {
                    tags.insert(.ignore)
                } else if hideZeroBalance, account.lamports == 0 {
                    tags.insert(.ignore)
                }

                return RenderableSolanaAccount(
                    account: account,
                    extraAction: .visiable,
                    tags: tags
                )
            }
    }

    /// Default sort order for solana accounts.
    /// 1. USDC and USDT has the highest priority.
    /// 2. Sort by balance in fiat.
    /// 3. Token with symbol.
    /// 4. Sort by largest amount of lamport.
    /// 5. Sort by symbol.
    /// 6. Sort by address.
    static var defaultSorter: (SolanaAccount, SolanaAccount) -> Bool {
        { lhs, rhs in
            // prefers non-liquidity token than liquidity tokens
            if lhs.token.isLiquidity != rhs.token.isLiquidity {
                return !lhs.token.isLiquidity
            }

            // prefers prioritized tokens than others
            let prioritizedTokenMints = [
                PublicKey.usdcMint.base58EncodedString,
                PublicKey.usdtMint.base58EncodedString,
            ]
            for mint in prioritizedTokenMints {
                if mint == lhs.token.address || mint == rhs.token.address {
                    return mint == lhs.token.address
                }
            }

            // prefers token which more value than the other in fiat
            if lhs.amountInFiat != rhs.amountInFiat {
                return lhs.amountInFiatDouble > rhs.amountInFiatDouble
            }

            // prefers known token than unknown ones
            if lhs.token.symbol.isEmpty != rhs.token.symbol.isEmpty {
                return !lhs.token.symbol.isEmpty
            }

            // prefers token which more balance than the others
            if lhs.amount != rhs.amount {
                return lhs.amount.orZero > rhs.amount.orZero
            }

            // sort by symbol
            if lhs.token.symbol != rhs.token.symbol {
                return lhs.token.symbol < rhs.token.symbol
            }

            // then name
            return lhs.token.name < rhs.token.name
        }
    }
}
