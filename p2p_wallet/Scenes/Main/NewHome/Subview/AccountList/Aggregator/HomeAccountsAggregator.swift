//
//  HomeDataAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 18.04.2023.
//

import Foundation
import KeyAppKitCore
import Web3
import Wormhole

struct HomeAccountsAggregator: DataAggregator {
    func transform(
        input: (
            solanaAccounts: [RenderableSolanaAccount],
            ethereumAccounts: [RenderableEthereumAccount]
        )
    )
    -> (primary: [any RenderableAccount], secondary: [any RenderableAccount]) {
        let (solanaAccounts, ethereumAccounts) = input

        let mergedAccounts: [any RenderableAccount] = ethereumAccounts + solanaAccounts

        // Filter hidden accounts
        mergedAccounts = mergedAccounts.filter { account in
            if account.tags.contains(.hidden) {
                return false
            }

            return true
        }

        // Split into two groups
        func primaryFilter(account: any RenderableAccount) -> Bool {
            if account.tags.contains(.favourite) {
                return true
            }

            if account.tags.contains(.ignore) {
                return false
            }
            return true
        }

        let primaryAccounts = mergedAccounts.filter(primaryFilter)
        let secondaryAccounts = mergedAccounts.filter { !primaryFilter(account: $0) }

        return (primaryAccounts, secondaryAccounts)
    }
}
