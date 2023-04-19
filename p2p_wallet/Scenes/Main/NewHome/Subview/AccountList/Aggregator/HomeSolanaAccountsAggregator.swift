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
struct HomeSolanaAccountsAggregator: Aggregator {
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
            .filter { !$0.data.isNFTToken }
            .sorted(by: Self.defaultSorter)
            .map { account in
                var tags: AccountTags = []

                if favourites.contains(account.data.pubkey ?? "") {
                    tags.insert(.favourite)
                } else if ignores.contains(account.data.pubkey ?? "") {
                    tags.insert(.ignore)
                } else if hideZeroBalance, account.data.lamports == 0 {
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
            if lhs.data.token.isLiquidity != rhs.data.token.isLiquidity {
                return !lhs.data.token.isLiquidity
            }

            // prefers prioritized tokens than others
            let prioritizedTokenMints = [
                PublicKey.usdcMint.base58EncodedString,
                PublicKey.usdtMint.base58EncodedString,
            ]
            for mint in prioritizedTokenMints {
                if mint == lhs.data.token.address || mint == rhs.data.token.address {
                    return mint == lhs.data.token.address
                }
            }

            // prefers token which more value than the other in fiat
            if lhs.amountInFiat != rhs.amountInFiat {
                return lhs.amountInFiatDouble > rhs.amountInFiatDouble
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
